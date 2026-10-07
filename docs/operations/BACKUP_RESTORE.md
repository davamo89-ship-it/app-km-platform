# App KM — Backup y restauración PostgreSQL

## Principios

1. Un backup no se considera confiable hasta que puede restaurarse.
2. Nunca almacenar contraseñas en scripts, Git o archivos de documentación.
3. Los archivos `.dump` no deben versionarse.
4. Mantener al menos una copia fuera del servidor que ejecuta PostgreSQL cuando
   App KM entre al piloto real.
5. Si Identity y Athletes usan bases físicas diferentes, ejecutar el proceso
   para cada base.

## Requisito local

Los comandos PostgreSQL (`pg_dump`, `pg_restore`, `createdb`, `dropdb`, `psql`)
deben estar disponibles en PATH o indicarse mediante los parámetros de los
scripts.

En PowerShell:

```powershell
$env:PGPASSWORD="<definir-solo-en-la-sesion>"
```

No guardar ese valor en archivos.

## Crear backup

Desde la raíz del repositorio:

```powershell
.\scripts\operations\Backup-Postgres.ps1 `
  -HostName localhost `
  -Port 5433 `
  -Database appkm `
  -Username appkm
```

Se crea:
- archivo `.dump` en formato custom;
- archivo `.sha256`;
- limpieza opcional de backups locales antiguos (14 días por defecto).

## Restore drill seguro

El drill crea una base temporal con nombre
`appkm_restore_drill_YYYYMMDDHHMMSS`, restaura el dump, ejecuta verificaciones
básicas y elimina la base temporal.

```powershell
.\scripts\operations\Test-PostgresRestore.ps1 `
  -BackupFile .\backups\appkm_YYYYMMDD_HHMMSS.dump `
  -HostName localhost `
  -Port 5433 `
  -Username appkm `
  -ConfirmDrill
```

Nunca usar la base de producción como base del drill.

## Restauración real

La base destino debe existir. El script exige confirmación explícita:

```powershell
.\scripts\operations\Restore-Postgres.ps1 `
  -BackupFile .\backups\appkm_YYYYMMDD_HHMMSS.dump `
  -TargetDatabase appkm_restored `
  -HostName localhost `
  -Port 5433 `
  -Username appkm `
  -ConfirmRestore
```

Antes de reemplazar una base productiva:

1. detener o bloquear escrituras;
2. obtener un backup del estado actual si todavía es posible;
3. restaurar primero en una base alterna;
4. ejecutar validaciones;
5. documentar el punto exacto de recuperación;
6. cambiar tráfico únicamente cuando la restauración esté verificada.

## Política inicial del piloto

- backup diario como mínimo;
- retención local mínima sugerida: 14 días;
- copia externa/off-site antes de manejar datos reales críticos;
- restore drill mensual;
- verificar SHA256 antes de una restauración.
