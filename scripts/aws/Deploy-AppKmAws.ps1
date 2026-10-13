[CmdletBinding()]
param(
    [string]$Region = 'us-east-1',
    [string]$StackName = 'appkm-staging',
    [string]$FirebaseServiceAccount = 'C:\AppKmSecrets\firebase-admin.json',
    [switch]$ResumeCompute
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$env:AWS_PAGER = ''

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$template = Join-Path $repoRoot 'infrastructure\aws\appkm-staging.yaml'

function Assert-Command([string]$Name) {
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "No se encontró '$Name'. Instálelo/configúrelo antes de continuar."
    }
}



function Write-Utf8NoBom([string]$Path, [string]$Content) {
    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $encoding)
}

function Test-StravaSecretInitialized([string]$SecretArn) {
    $raw = aws secretsmanager get-secret-value `
        --secret-id $SecretArn `
        --region $Region `
        --query SecretString `
        --output text `
        --no-cli-pager 2>$null

    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($raw) -or $raw -eq 'None') {
        return $false
    }

    try {
        $obj = $raw | ConvertFrom-Json
        return (
            -not [string]::IsNullOrWhiteSpace([string]$obj.clientId) -and
            -not [string]::IsNullOrWhiteSpace([string]$obj.clientSecret) -and
            [string]$obj.clientId -ne 'SET_ME' -and
            [string]$obj.clientSecret -ne 'SET_ME'
        )
    }
    catch {
        return $false
    }
    finally {
        $raw = $null
    }
}

function Get-StackStatus {
    $status = aws cloudformation describe-stacks `
        --stack-name $StackName `
        --region $Region `
        --query 'Stacks[0].StackStatus' `
        --output text `
        --no-cli-pager 2>$null

    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($status) -or $status -eq 'None') {
        return $null
    }

    return $status.Trim()
}

function Show-CloudFormationDeleteFailure {
    Write-Host ''
    Write-Host 'Recurso(s) que impidieron eliminar el stack:'
    aws cloudformation describe-stack-events `
        --stack-name $StackName `
        --region $Region `
        --query "StackEvents[?ResourceStatus=='DELETE_FAILED'].[Timestamp,LogicalResourceId,ResourceType,ResourceStatusReason]" `
        --output table `
        --no-cli-pager
}

function Remove-UnusableRollbackStack {
    $status = Get-StackStatus
    if ($null -eq $status) {
        return
    }

    $deletableFailedStates = @(
        'ROLLBACK_COMPLETE',
        'ROLLBACK_FAILED',
        'CREATE_FAILED',
        'DELETE_FAILED'
    )

    if ($deletableFailedStates -notcontains $status) {
        return
    }

    Write-Host "El stack $StackName esta en $status. Eliminandolo antes de reintentar..."
    aws cloudformation delete-stack `
        --stack-name $StackName `
        --region $Region `
        --no-cli-pager
    if ($LASTEXITCODE -ne 0) {
        Show-CloudFormationDeleteFailure
        throw "No se pudo iniciar la eliminacion del stack $StackName."
    }

    aws cloudformation wait stack-delete-complete `
        --stack-name $StackName `
        --region $Region `
        --no-cli-pager
    if ($LASTEXITCODE -ne 0) {
        $afterDelete = Get-StackStatus
        if ($afterDelete -eq 'DELETE_FAILED') {
            Show-CloudFormationDeleteFailure
            throw "El stack $StackName quedo en DELETE_FAILED. No se forzara la eliminacion automaticamente para evitar dejar recursos facturables huerfanos."
        }
        throw "El stack $StackName no pudo eliminarse completamente. Estado actual: $afterDelete"
    }

    Write-Host 'Stack anterior eliminado. Continuando con una creacion limpia.'
}

function Show-CloudFormationFailure {
    Write-Host ''
    Write-Host 'Causa(s) de CloudFormation:'
    aws cloudformation describe-stack-events `
        --stack-name $StackName `
        --region $Region `
        --query "StackEvents[?((ResourceStatus=='CREATE_FAILED' || ResourceStatus=='UPDATE_FAILED') && !contains(ResourceStatusReason, 'cancelled'))].[Timestamp,LogicalResourceId,ResourceType,ResourceStatusReason]" `
        --output table `
        --no-cli-pager
}

function Get-Output([string]$Key) {
    $value = aws cloudformation describe-stacks `
        --stack-name $StackName `
        --region $Region `
        --query "Stacks[0].Outputs[?OutputKey=='$Key'].OutputValue | [0]" `
        --output text
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($value) -or $value -eq 'None') {
        throw "No fue posible leer el output '$Key'."
    }
    return $value.Trim()
}

function ConvertTo-HttpsBaseUrl([string]$Endpoint) {
    $value = $Endpoint.Trim().TrimEnd('/')
    if ($value -notmatch '^https://') { $value = 'https://' + $value }
    $uri = [uri]$value
    if ($uri.Scheme -ne 'https' -or [string]::IsNullOrWhiteSpace($uri.Host) -or $uri.AbsolutePath -ne '/' -or $uri.Query -or $uri.Fragment -or $uri.UserInfo) {
        throw 'AWS devolvio un endpoint HTTPS inesperado.'
    }
    return $value
}

function Deploy-Stack(
    [string]$DeployMigration,
    [string]$DeployCompute,
    [string]$IdentityImage,
    [string]$AthletesImage,
    [string]$MigrationImage,
    [string]$SnsArn,
    [string]$CallbackUri = 'https://localhost/api/v1/athletes/strava/callback'
) {
    aws cloudformation deploy `
        --template-file $template `
        --stack-name $StackName `
        --region $Region `
        --capabilities CAPABILITY_NAMED_IAM `
        --no-fail-on-empty-changeset `
        --parameter-overrides `
            EnvironmentName=staging `
            DeployMigration=$DeployMigration `
            DeployCompute=$DeployCompute `
            IdentityImageUri=$IdentityImage `
            AthletesImageUri=$AthletesImage `
            MigrationImageUri=$MigrationImage `
            SnsPlatformApplicationArn=$SnsArn `
            StravaRedirectUri=$CallbackUri

    if ($LASTEXITCODE -ne 0) {
        Show-CloudFormationFailure
        throw 'CloudFormation fallo.'
    }
}

Assert-Command aws
if (-not $ResumeCompute) { Assert-Command docker }

Write-Host 'Validando sesion AWS...'
aws sts get-caller-identity --region $Region --no-cli-pager | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw 'AWS CLI no tiene una sesion valida. Ejecute aws login.'
}

if ($ResumeCompute) {
    $resumeStatus = Get-StackStatus
    if ($resumeStatus -notin @('UPDATE_ROLLBACK_COMPLETE', 'UPDATE_COMPLETE')) {
        throw "No se puede reanudar 6/7 con el stack en $resumeStatus. Espere a que termine el rollback; no borre el stack."
    }
    Write-Host 'Reanudacion 6/7: se reutilizaran las imagenes y las migraciones ya ejecutadas.'
}

Write-Host 'Validando template CloudFormation...'
aws cloudformation validate-template `
    --template-body "file://$template" `
    --region $Region `
    --no-cli-pager | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw 'El template CloudFormation no paso validate-template.'
}

if (-not $ResumeCompute) {
    Remove-UnusableRollbackStack
    Write-Host '1/7 - Creando foundation AWS...'
    Deploy-Stack 'false' 'false' '' '' '' 'NOT_CONFIGURED'
}

$identityRepo = Get-Output 'IdentityRepositoryUri'
$athletesRepo = Get-Output 'AthletesRepositoryUri'
$migrationRepo = Get-Output 'MigrationRepositoryUri'
$stravaSecretArn = Get-Output 'StravaSecretArn'

Write-Host '2/7 - Guardando Strava en Secrets Manager...'
$forceStravaUpdate = (
    -not [string]::IsNullOrWhiteSpace($env:APPKM_STRAVA_CLIENT_ID) -or
    -not [string]::IsNullOrWhiteSpace($env:APPKM_STRAVA_CLIENT_SECRET)
)

if ((Test-StravaSecretInitialized $stravaSecretArn) -and -not $forceStravaUpdate) {
    Write-Host 'Strava ya esta configurado en Secrets Manager. Se reutilizara el secreto existente.'
}
else {
    $clientId = $env:APPKM_STRAVA_CLIENT_ID
    if ([string]::IsNullOrWhiteSpace($clientId)) {
        $clientId = Read-Host 'Strava Client ID'
    }
    $clientSecret = $env:APPKM_STRAVA_CLIENT_SECRET
    if ([string]::IsNullOrWhiteSpace($clientSecret)) {
        $secure = Read-Host 'Strava Client Secret (no se mostrara)' -AsSecureString
        $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
        try { $clientSecret = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr) }
        finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr) }
    }
    if ($clientId -notmatch '^\d+$' -or [string]::IsNullOrWhiteSpace($clientSecret) -or $clientSecret -eq 'SET_ME') {
        throw 'Strava Client ID debe ser numerico y Client Secret no puede estar vacio ni ser SET_ME.'
    }
    $stravaJson = ConvertTo-Json -InputObject @{ clientId = [string]$clientId; clientSecret = [string]$clientSecret } -Depth 3 -Compress
    # Keep the temporary payload outside the repository, next to the local credentials.
    $secretsDirectory = Split-Path -Parent $FirebaseServiceAccount
    if (-not (Test-Path -LiteralPath $secretsDirectory -PathType Container)) {
        throw 'No existe la carpeta local de credenciales. Revise FirebaseServiceAccount.'
    }
    $stravaFile = Join-Path $secretsDirectory ('appkm-strava-' + [guid]::NewGuid().ToString('N') + '.json')
    $readBack = $null
    $verified = $null
    try {
        Write-Utf8NoBom $stravaFile $stravaJson
        aws secretsmanager put-secret-value `
            --secret-id $stravaSecretArn `
            --secret-string "file://$stravaFile" `
            --region $Region `
            --no-cli-pager | Out-Null
        if ($LASTEXITCODE -ne 0) { throw 'No se pudo guardar Strava en Secrets Manager.' }

        $readBack = aws secretsmanager get-secret-value `
            --secret-id $stravaSecretArn `
            --region $Region `
            --query SecretString `
            --output text `
            --no-cli-pager
        if ($LASTEXITCODE -ne 0) { throw 'No se pudo verificar el secreto Strava guardado.' }
        try { $verified = ConvertFrom-Json -InputObject ($readBack -join "`n") }
        catch { throw 'El secreto Strava guardado no es JSON valido. Su contenido no se mostrara.' }
        if ([string]$verified.clientId -cne [string]$clientId -or [string]$verified.clientSecret -cne [string]$clientSecret) {
            throw 'La verificacion de Strava no coincide con los valores ingresados.'
        }
        Write-Host 'Strava guardado y verificado: JSON valido, valores conservados.'
    }
    finally {
        Remove-Item -LiteralPath $stravaFile -Force -ErrorAction SilentlyContinue
        $clientSecret = $null
        $secure = $null
        $stravaJson = $null
        $readBack = $null
        $verified = $null
    }
}

if (-not $ResumeCompute) {
Write-Host '3/7 - Configurando Amazon SNS para FCM...'
$snsArn = 'NOT_CONFIGURED'
if (Test-Path $FirebaseServiceAccount) {
    $firebaseFile = Get-Item -LiteralPath $FirebaseServiceAccount
    if ($firebaseFile.Length -le 0 -or $firebaseFile.Length -gt 1048576) {
        throw "El archivo Firebase service account tiene un tamano inesperado ($($firebaseFile.Length) bytes). No se enviara a SNS."
    }

    $serviceJson = Get-Content -LiteralPath $FirebaseServiceAccount -Raw
    try {
        $firebaseMeta = $serviceJson | ConvertFrom-Json
        if (
            [string]$firebaseMeta.type -ne 'service_account' -or
            [string]::IsNullOrWhiteSpace([string]$firebaseMeta.project_id) -or
            [string]::IsNullOrWhiteSpace([string]$firebaseMeta.client_email) -or
            [string]::IsNullOrWhiteSpace([string]$firebaseMeta.private_key)
        ) {
            throw 'El JSON no parece una cuenta de servicio Firebase/Google valida.'
        }
    }
    catch {
        throw 'No se pudo validar el archivo local como service account JSON. Revise su formato sin compartir su contenido.'
    }
    finally {
        $firebaseMeta = $null
    }

    $existingArn = aws sns list-platform-applications `
        --region $Region `
        --query "PlatformApplications[?ends_with(PlatformApplicationArn, ':app/GCM/appkm-staging-android')].PlatformApplicationArn | [0]" `
        --output text `
        --no-cli-pager
    if ($LASTEXITCODE -ne 0) {
        throw 'No se pudo consultar las platform applications de SNS.'
    }

    # Serialize the raw JSON as a STRING; never serialize the parsed credential object.
    # This escapes quotes/newlines correctly without traversing PowerShell metadata.
    $attrsJson = ConvertTo-Json -InputObject @{ PlatformCredential = [string]$serviceJson } -Depth 3 -Compress
    $roundTrip = ConvertFrom-Json -InputObject $attrsJson
    if ([string]$roundTrip.PlatformCredential -cne $serviceJson) {
        throw 'La serializacion de PlatformCredential no conserva el archivo original.'
    }
    $roundTrip = $null

    if ($existingArn -and $existingArn -ne 'None') {
        $snsArn = $existingArn.Trim()
        $attrsFile = Join-Path $firebaseFile.DirectoryName ('appkm-sns-attrs-' + [guid]::NewGuid().ToString('N') + '.json')
        Write-Utf8NoBom $attrsFile $attrsJson
        try {
            aws sns set-platform-application-attributes `
                --platform-application-arn $snsArn `
                --attributes "file://$attrsFile" `
                --region $Region `
                --no-cli-pager | Out-Null
            if ($LASTEXITCODE -ne 0) {
                throw 'SNS rechazo la actualizacion de las credenciales FCM.'
            }
        }
        finally {
            Remove-Item $attrsFile -Force -ErrorAction SilentlyContinue
        }
    }
    else {
        $attrsFile = Join-Path $firebaseFile.DirectoryName ('appkm-sns-attrs-' + [guid]::NewGuid().ToString('N') + '.json')
        Write-Utf8NoBom $attrsFile $attrsJson
        try {
            $snsArn = aws sns create-platform-application `
                --name appkm-staging-android `
                --platform GCM `
                --attributes "file://$attrsFile" `
                --region $Region `
                --query PlatformApplicationArn `
                --output text `
                --no-cli-pager
            if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($snsArn) -or $snsArn -eq 'None') {
                throw 'SNS no pudo crear la platform application FCM.'
            }
            $snsArn = $snsArn.Trim()
        }
        finally {
            Remove-Item $attrsFile -Force -ErrorAction SilentlyContinue
        }
    }

    $authMethod = aws sns get-platform-application-attributes `
        --platform-application-arn $snsArn `
        --region $Region `
        --query 'Attributes.AuthenticationMethod' `
        --output text `
        --no-cli-pager
    if ($LASTEXITCODE -ne 0) {
        throw 'SNS creo/actualizo la platform application, pero no fue posible validar el metodo de autenticacion FCM.'
    }
    if ([string]::IsNullOrWhiteSpace($authMethod) -or $authMethod -eq 'None' -or $authMethod.Trim().ToLowerInvariant() -ne 'token') {
        throw "SNS no quedo usando autenticacion FCM por token. AuthenticationMethod=$authMethod"
    }

    Write-Host 'Amazon SNS para FCM configurado correctamente (AuthenticationMethod=Token).'
    $serviceJson = $null
    $attrsJson = $null
}
else {
    throw "No se encontro $FirebaseServiceAccount. Se detiene el despliegue antes de 4/7 hasta configurar SNS."
}

Write-Host '4/7 - Build y push de imágenes a ECR...'
$registry = ($identityRepo -split '/')[0]
aws ecr get-login-password --region $Region | docker login --username AWS --password-stdin $registry
if ($LASTEXITCODE -ne 0) { throw 'Falló login de ECR.' }

Push-Location $repoRoot
try {
    docker build -f backend\Dockerfile.Identity -t "${identityRepo}:aws-staging" backend
    if ($LASTEXITCODE -ne 0) { throw 'Falló Docker Identity.' }
    docker push "${identityRepo}:aws-staging"
    if ($LASTEXITCODE -ne 0) { throw 'Falló push Identity.' }

    docker build -f backend\Dockerfile.Athletes -t "${athletesRepo}:aws-staging" backend
    if ($LASTEXITCODE -ne 0) { throw 'Falló Docker Athletes.' }
    docker push "${athletesRepo}:aws-staging"
    if ($LASTEXITCODE -ne 0) { throw 'Falló push Athletes.' }

    docker build -f backend\Dockerfile.Migrations -t "${migrationRepo}:aws-staging" backend
    if ($LASTEXITCODE -ne 0) { throw 'Falló Docker Migrations.' }
    docker push "${migrationRepo}:aws-staging"
    if ($LASTEXITCODE -ne 0) { throw 'Falló push Migrations.' }
}
finally {
    Pop-Location
}

Write-Host '5/7 - Creando y ejecutando tarea de migraciones dentro de AWS...'
Deploy-Stack 'true' 'false' "${identityRepo}:aws-staging" "${athletesRepo}:aws-staging" "${migrationRepo}:aws-staging" $snsArn
$cluster = Get-Output 'ClusterName'
$taskDefinition = Get-Output 'MigrationTaskDefinitionArn'
$subnetA = Get-Output 'PublicSubnetA'
$subnetB = Get-Output 'PublicSubnetB'
$ecsSg = Get-Output 'EcsSecurityGroup'

$network = "awsvpcConfiguration={subnets=[$subnetA,$subnetB],securityGroups=[$ecsSg],assignPublicIp=ENABLED}"
$taskArn = aws ecs run-task `
    --cluster $cluster `
    --task-definition $taskDefinition `
    --launch-type FARGATE `
    --network-configuration $network `
    --region $Region `
    --query 'tasks[0].taskArn' `
    --output text
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($taskArn) -or $taskArn -eq 'None') {
    throw 'No se pudo iniciar la tarea de migraciones.'
}
aws ecs wait tasks-stopped --cluster $cluster --tasks $taskArn --region $Region
$exitCode = aws ecs describe-tasks --cluster $cluster --tasks $taskArn --region $Region --query 'tasks[0].containers[0].exitCode' --output text
if ($exitCode -ne '0') {
    throw "Las migraciones AWS fallaron. ExitCode=$exitCode. Revise CloudWatch /appkm/staging/migrations."
}

}
else {
    $snsArn = aws sns list-platform-applications `
        --region $Region `
        --query "PlatformApplications[?ends_with(PlatformApplicationArn, ':app/GCM/appkm-staging-android')].PlatformApplicationArn | [0]" `
        --output text `
        --no-cli-pager
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($snsArn) -or $snsArn -eq 'None') {
        throw 'No se encontro la platform application SNS ya configurada. No se reanudara 6/7.'
    }
    $snsArn = $snsArn.Trim()
    $authMethod = aws sns get-platform-application-attributes `
        --platform-application-arn $snsArn `
        --region $Region `
        --query 'Attributes.AuthenticationMethod' `
        --output text `
        --no-cli-pager
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($authMethod) -or $authMethod.Trim() -ne 'Token') {
        throw 'No se pudo confirmar SNS con autenticacion Token.'
    }
    Write-Host 'SNS verificado. Se omiten build/push y migraciones en esta reanudacion.'
}

Write-Host '6/7 - Desplegando APIs con ECS Express Mode (HTTPS administrado)...'
# The actual hostname is assigned by AWS; never derive it from ServiceName.
$existingEndpoint = aws cloudformation describe-stacks `
    --stack-name $StackName `
    --region $Region `
    --query "Stacks[0].Outputs[?OutputKey=='AthletesExpressEndpoint'].OutputValue | [0]" `
    --output text `
    --no-cli-pager
if ($LASTEXITCODE -ne 0) { throw 'No se pudo consultar el endpoint de Athletes.' }
$callbackForDeploy = 'https://localhost/api/v1/athletes/strava/callback'
if (-not [string]::IsNullOrWhiteSpace($existingEndpoint) -and $existingEndpoint -ne 'None') {
    $callbackForDeploy = (ConvertTo-HttpsBaseUrl $existingEndpoint) + '/api/v1/athletes/strava/callback'
}
Deploy-Stack 'true' 'true' "${identityRepo}:aws-staging" "${athletesRepo}:aws-staging" "${migrationRepo}:aws-staging" $snsArn $callbackForDeploy

$assignedCallback = (ConvertTo-HttpsBaseUrl (Get-Output 'AthletesExpressEndpoint')) + '/api/v1/athletes/strava/callback'
if ($assignedCallback -cne $callbackForDeploy) {
    # A first creation needs two passes to avoid a CloudFormation self-reference.
    Write-Host 'Aplicando el callback Strava con el endpoint recien asignado por AWS...'
    Deploy-Stack 'true' 'true' "${identityRepo}:aws-staging" "${athletesRepo}:aws-staging" "${migrationRepo}:aws-staging" $snsArn $assignedCallback
    $confirmedCallback = (ConvertTo-HttpsBaseUrl (Get-Output 'AthletesExpressEndpoint')) + '/api/v1/athletes/strava/callback'
    if ($confirmedCallback -cne $assignedCallback) {
        throw 'El endpoint cambio durante la actualizacion. Reanude con -ResumeCompute antes de probar OAuth.'
    }
}

Write-Host '7/7 - Generando launcher Flutter AWS...'
$identityApi = ConvertTo-HttpsBaseUrl (Get-Output 'IdentityExpressEndpoint')
$athletesApi = ConvertTo-HttpsBaseUrl (Get-Output 'AthletesExpressEndpoint')
$userPoolId = Get-Output 'UserPoolId'
$userPoolClientId = Get-Output 'UserPoolClientId'
$identityPoolId = Get-Output 'IdentityPoolId'
$stravaCallback = $athletesApi + '/api/v1/athletes/strava/callback'

$launcher = Join-Path $repoRoot 'scripts\aws\Run-AppKmAwsStaging.ps1'
@"
`$ErrorActionPreference = 'Stop'
cd '$repoRoot\mobile'
flutter pub get
flutter run -d 138097055K002340 ``
  --dart-define=AWS_REGION=$Region ``
  --dart-define=COGNITO_USER_POOL_ID=$userPoolId ``
  --dart-define=COGNITO_USER_POOL_CLIENT_ID=$userPoolClientId ``
  --dart-define=COGNITO_IDENTITY_POOL_ID=$identityPoolId ``
  --dart-define=IDENTITY_API_URL=$identityApi ``
  --dart-define=ATHLETES_API_URL=$athletesApi ``
  --dart-define=STRAVA_AUTH_BACKEND_URL=$athletesApi ``
  --dart-define=STRAVA_REDIRECT_URI=$stravaCallback
"@ | Set-Content -LiteralPath $launcher -Encoding UTF8

Write-Host ''
Write-Host 'AWS App KM staging desplegado.'
Write-Host "Identity API: $identityApi"
Write-Host "Athletes API: $athletesApi"
Write-Host "Strava callback: $stravaCallback"
Write-Host "Authorization Callback Domain: $(([uri]$athletesApi).Host)"
Write-Host "Flutter: .\scripts\aws\Run-AppKmAwsStaging.ps1"
Write-Host ''
Write-Host 'IMPORTANTE: actualice Authorization Callback Domain en Strava con el dominio mostrado antes de probar OAuth.'
