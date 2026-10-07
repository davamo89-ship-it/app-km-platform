[CmdletBinding()]
param(
    [string]$BlueprintPath = ".\render.yaml"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $BlueprintPath)) {
    throw "No existe $BlueprintPath"
}

Write-Host "Validando estructura básica de render.yaml..."

$content =
    Get-Content $BlueprintPath -Raw

$requiredTokens = @(
    "appkm-identity-staging",
    "appkm-athletes-staging",
    "appkm-staging-postgres",
    "Dockerfile.Identity",
    "Dockerfile.Athletes",
    "/health/ready"
)

foreach ($token in $requiredTokens) {
    if (-not $content.Contains($token)) {
        throw "render.yaml no contiene el elemento requerido: $token"
    }
}

Write-Host "Estructura básica correcta."

$renderCommand =
    Get-Command render -ErrorAction SilentlyContinue

if ($null -ne $renderCommand) {
    Write-Host "Render CLI detectado. Ejecutando validación oficial..."

    render blueprints validate $BlueprintPath

    if ($LASTEXITCODE -ne 0) {
        throw "Render CLI reportó un Blueprint inválido."
    }

    Write-Host "Render CLI: Blueprint válido."
}
else {
    Write-Host ""
    Write-Host "Render CLI no está instalado."
    Write-Host "La validación oficial se realizará también al crear el Blueprint en Render."
}
