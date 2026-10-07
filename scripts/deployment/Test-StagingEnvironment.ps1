[CmdletBinding()]
param(
    [string]$EnvFile =
        ".\infrastructure\docker\compose\staging.env.example",

    [string]$ComposeFile =
        ".\infrastructure\docker\compose\docker-compose.staging.yml"
)

$ErrorActionPreference = "Stop"

if (-not (Test-Path $EnvFile)) {
    throw "No existe el archivo de variables: $EnvFile"
}

if (-not (Test-Path $ComposeFile)) {
    throw "No existe el compose de staging: $ComposeFile"
}

Write-Host "Validando Docker Compose de staging..."

docker compose `
    --env-file $EnvFile `
    -f $ComposeFile `
    config `
    --quiet

if ($LASTEXITCODE -ne 0) {
    throw "docker compose config falló."
}

Write-Host "Docker Compose válido."
Write-Host ""
Write-Host "Nota: staging.env.example contiene placeholders."
Write-Host "Esta validación comprueba estructura, no autenticación real ni secretos."
