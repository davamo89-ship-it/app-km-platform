[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$BackupFile,

    [string]$HostName = "localhost",
    [int]$Port = 5433,
    [string]$Username = "appkm",
    [string]$CreateDbPath = "createdb",
    [string]$DropDbPath = "dropdb",
    [string]$PgRestorePath = "pg_restore",
    [string]$PsqlPath = "psql",

    [switch]$ConfirmDrill
)

$ErrorActionPreference = "Stop"

if (-not $ConfirmDrill) {
    throw "Restore drill bloqueado. Vuelva a ejecutar con -ConfirmDrill."
}

if (-not (Test-Path $BackupFile)) {
    throw "No existe el backup: $BackupFile"
}

if ([string]::IsNullOrWhiteSpace($env:PGPASSWORD)) {
    throw "PGPASSWORD no está definido."
}

$drillDatabase =
    "appkm_restore_drill_" +
    (Get-Date -Format "yyyyMMddHHmmss")

Write-Host "Base temporal de restore drill: $drillDatabase"

try {
    & $CreateDbPath `
        --host=$HostName `
        --port=$Port `
        --username=$Username `
        $drillDatabase

    if ($LASTEXITCODE -ne 0) {
        throw "createdb falló con código $LASTEXITCODE."
    }

    & $PgRestorePath `
        --host=$HostName `
        --port=$Port `
        --username=$Username `
        --dbname=$drillDatabase `
        --no-owner `
        --no-privileges `
        --exit-on-error `
        $BackupFile

    if ($LASTEXITCODE -ne 0) {
        throw "pg_restore falló con código $LASTEXITCODE."
    }

    $verificationSql = @"
SELECT current_database();
SELECT COUNT(*) AS appkm_schema_count
FROM information_schema.schemata
WHERE schema_name IN ('identity', 'athletes');
SELECT COUNT(*) AS migration_table_count
FROM information_schema.tables
WHERE table_name = '__EFMigrationsHistory';
"@

    & $PsqlPath `
        --host=$HostName `
        --port=$Port `
        --username=$Username `
        --dbname=$drillDatabase `
        --set=ON_ERROR_STOP=1 `
        --command=$verificationSql

    if ($LASTEXITCODE -ne 0) {
        throw "La verificación SQL del restore drill falló."
    }

    Write-Host ""
    Write-Host "Restore drill completado correctamente."
}
finally {
    & $DropDbPath `
        --host=$HostName `
        --port=$Port `
        --username=$Username `
        --if-exists `
        $drillDatabase

    if ($LASTEXITCODE -ne 0) {
        Write-Warning "No fue posible eliminar automáticamente la DB temporal '$drillDatabase'."
    }
}
