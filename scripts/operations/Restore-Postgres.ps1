[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$BackupFile,

    [Parameter(Mandatory = $true)]
    [string]$TargetDatabase,

    [string]$HostName = "localhost",
    [int]$Port = 5433,
    [string]$Username = "appkm",
    [string]$PgRestorePath = "pg_restore",

    [switch]$ConfirmRestore
)

$ErrorActionPreference = "Stop"

if (-not $ConfirmRestore) {
    throw "Restauración bloqueada. Vuelva a ejecutar con -ConfirmRestore."
}

if (-not (Test-Path $BackupFile)) {
    throw "No existe el archivo de backup: $BackupFile"
}

if ([string]::IsNullOrWhiteSpace($env:PGPASSWORD)) {
    throw "PGPASSWORD no está definido."
}

$checksumFile = "$BackupFile.sha256"

if (Test-Path $checksumFile) {
    $expected =
        (Get-Content $checksumFile -Raw).Trim().Split(" ")[0].ToUpperInvariant()

    $actual =
        (Get-FileHash -Algorithm SHA256 -Path $BackupFile).Hash.ToUpperInvariant()

    if ($expected -ne $actual) {
        throw "El SHA256 del backup no coincide. Restauración cancelada."
    }

    Write-Host "Checksum SHA256 verificado."
}
else {
    Write-Warning "No existe archivo .sha256. Se continuará sin verificación de integridad."
}

Write-Host "Restaurando '$BackupFile' en '$TargetDatabase'..."

& $PgRestorePath `
    --host=$HostName `
    --port=$Port `
    --username=$Username `
    --dbname=$TargetDatabase `
    --clean `
    --if-exists `
    --no-owner `
    --no-privileges `
    --exit-on-error `
    $BackupFile

if ($LASTEXITCODE -ne 0) {
    throw "pg_restore falló con código $LASTEXITCODE."
}

Write-Host "Restauración completada."
