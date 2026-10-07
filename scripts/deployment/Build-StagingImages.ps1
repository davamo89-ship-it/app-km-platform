[CmdletBinding()]
param(
    [string]$IdentityTag = "appkm-identity-api:staging",
    [string]$AthletesTag = "appkm-athletes-api:staging"
)

$ErrorActionPreference = "Stop"

$repoRoot =
    Resolve-Path (
        Join-Path $PSScriptRoot "..\.."
    )

$backendPath =
    Join-Path $repoRoot "backend"

Write-Host "Construyendo Identity API..."
docker build `
    --file (Join-Path $backendPath "Dockerfile.Identity") `
    --tag $IdentityTag `
    $backendPath

if ($LASTEXITCODE -ne 0) {
    throw "Falló el build Docker de Identity API."
}

Write-Host ""
Write-Host "Construyendo Athletes API..."
docker build `
    --file (Join-Path $backendPath "Dockerfile.Athletes") `
    --tag $AthletesTag `
    $backendPath

if ($LASTEXITCODE -ne 0) {
    throw "Falló el build Docker de Athletes API."
}

Write-Host ""
Write-Host "Imágenes creadas:"
Write-Host "  $IdentityTag"
Write-Host "  $AthletesTag"
