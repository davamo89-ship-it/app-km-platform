[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ConnectionString,

    [switch]$ConfirmEmptyStaging
)

$ErrorActionPreference = "Stop"

if (-not $ConfirmEmptyStaging) {
    throw "Use -ConfirmEmptyStaging únicamente para la base NUEVA y vacía de staging."
}

if ([string]::IsNullOrWhiteSpace($ConnectionString)) {
    throw "ConnectionString es obligatoria."
}

$repoRoot =
    Resolve-Path (
        Join-Path $PSScriptRoot "..\..\.."
    )

$backend =
    Join-Path $repoRoot "backend"

Push-Location $backend

try {
    $env:ConnectionStrings__IdentityDatabase =
        $ConnectionString

    $env:ConnectionStrings__AthleteDatabase =
        $ConnectionString

    Write-Host "Verificando dotnet-ef..."

    dotnet ef --version

    if ($LASTEXITCODE -ne 0) {
        throw "dotnet-ef no está disponible. Instálelo antes de ejecutar migraciones."
    }

    Write-Host ""
    Write-Host "Aplicando migraciones Identity..."

    dotnet ef database update `
        --project src\AppKm\Modules\Identity\AppKm.Identity.Infrastructure\AppKm.Identity.Infrastructure.csproj `
        --startup-project src\AppKm\Modules\Identity\AppKm.Identity.Api\AppKm.Identity.Api.csproj `
        --context AppKm.Identity.Infrastructure.Persistence.IdentityDbContext

    if ($LASTEXITCODE -ne 0) {
        throw "Fallaron las migraciones de Identity."
    }

    Write-Host ""
    Write-Host "Aplicando migraciones Athletes..."

    dotnet ef database update `
        --project src\AppKm\Modules\Athletes\AppKm.Athletes.Infrastructure\AppKm.Athletes.Infrastructure.csproj `
        --startup-project src\AppKm\Modules\Athletes\AppKm.Athletes.Api\AppKm.Athletes.Api.csproj `
        --context AppKm.Athletes.Infrastructure.Persistence.AthleteDbContext

    if ($LASTEXITCODE -ne 0) {
        throw "Fallaron las migraciones de Athletes."
    }

    Write-Host ""
    Write-Host "Migraciones de staging completadas."
}
finally {
    Remove-Item Env:ConnectionStrings__IdentityDatabase -ErrorAction SilentlyContinue
    Remove-Item Env:ConnectionStrings__AthleteDatabase -ErrorAction SilentlyContinue
    Pop-Location
}
