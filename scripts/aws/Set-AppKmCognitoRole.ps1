[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Email,
    [Parameter(Mandatory = $true)][ValidateSet('Athlete','Merchant','Admin')][string]$Role,
    [string]$Region = 'us-east-1',
    [string]$StackName = 'appkm-staging'
)
$ErrorActionPreference = 'Stop'
$userPoolId = aws cloudformation describe-stacks --stack-name $StackName --region $Region --query "Stacks[0].Outputs[?OutputKey=='UserPoolId'].OutputValue | [0]" --output text
$username = aws cognito-idp list-users --user-pool-id $userPoolId --filter "email = `"$Email`"" --region $Region --query 'Users[0].Username' --output text
if (-not $username -or $username -eq 'None') { throw 'Usuario no encontrado en Cognito.' }
aws cognito-idp admin-add-user-to-group --user-pool-id $userPoolId --username $username --group-name $Role --region $Region
if ($LASTEXITCODE -ne 0) { throw 'No fue posible asignar el grupo.' }
Write-Host "Grupo $Role asignado a $Email. Cierre sesión e ingrese de nuevo para renovar claims."
