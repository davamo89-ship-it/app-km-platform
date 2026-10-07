[CmdletBinding()]
param(
    [string]$HostName = "localhost",
    [int]$Port = 5433,
    [string]$Database = "appkm",
    [string]$Username = "appkm",
    [string]$OutputDirectory = ".\backups",
    [string]$PgDumpPath = "pg_dump",
    [int]$RetentionDays = 14
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($env:PGPASSWORD)) {
    throw "PGPASSWORD no está definido. Defínalo solo en la sesión actual antes de ejecutar el backup."
}

New-Item -ItemType Directory -Force -Path $OutputDirectory | Out-Null

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupFile = Join-Path $OutputDirectory "$Database`_$timestamp.dump"
$checksumFile = "$backupFile.sha256"

Write-Host "Creando backup PostgreSQL..."
Write-Host "Base: $Database"
Write-Host "Servidor: $HostName`:$Port"
Write-Host "Archivo: $backupFile"

& $PgDumpPath `
    --host=$HostName `
    --port=$Port `
    --username=$Username `
    --dbname=$Database `
    --format=custom `
    --compress=9 `
    --no-owner `
    --no-privileges `
    --file=$backupFile

if ($LASTEXITCODE -ne 0) {
    throw "pg_dump falló con código $LASTEXITCODE."
}

$hash = Get-FileHash -Algorithm SHA256 -Path $backupFile
"$($hash.Hash)  $([System.IO.Path]::GetFileName($backupFile))" |
    Set-Content -Encoding ASCII $checksumFile

if ($RetentionDays -gt 0) {
    $cutoff = (Get-Date).AddDays(-$RetentionDays)

    Get-ChildItem $OutputDirectory -File |
        Where-Object {
            $_.LastWriteTime -lt $cutoff -and
            ($_.Extension -eq ".dump" -or $_.Name.EndsWith(".dump.sha256"))
        } |
        Remove-Item -Force
}

Write-Host ""
Write-Host "Backup completado."
Write-Host "SHA256: $($hash.Hash)"
Write-Host "Backup: $backupFile"
Write-Host "Checksum: $checksumFile"
