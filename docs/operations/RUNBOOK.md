# App KM — Runbook operativo

## Objetivo

Este documento define la respuesta mínima para incidentes del piloto de App KM.
No contiene secretos ni credenciales.

## Endpoints operativos

Cada API expone:

- `/health/live`: confirma que el proceso HTTP está vivo. No depende de PostgreSQL.
- `/health/ready`: confirma que las dependencias requeridas están disponibles.
- `/health`: alias compatible de readiness.
- `/ops/metrics`: resumen operativo del proceso: solicitudes, errores 4xx/5xx,
  solicitudes activas y latencias.

El encabezado `X-Correlation-ID` debe conservarse en todo incidente. Si el
cliente envía un ID válido, la API lo reutiliza; de lo contrario genera uno.

## Clasificación inicial

### API no responde

1. Consultar `/health/live`.
2. Si no responde, revisar proceso/contenedor, puertos y logs de inicio.
3. Si responde pero `/health/ready` falla, tratarlo como dependencia no lista,
   normalmente PostgreSQL.
4. Registrar hora, servicio, endpoint y correlation ID.

### PostgreSQL no disponible

1. Confirmar `/health/ready`.
2. Verificar conectividad al servidor PostgreSQL.
3. Verificar espacio en disco y conexiones.
4. No ejecutar migraciones destructivas durante un incidente sin backup.
5. Si hay sospecha de pérdida/corrupción, pasar al procedimiento de recuperación.

### Aumento de errores HTTP 5xx

1. Revisar `/ops/metrics`.
2. Comparar `serverErrorRequests` con `totalRequests`.
3. Buscar en logs el `CorrelationId`.
4. Identificar endpoint, excepción y dependencia.
5. Si afecta canjes/puntos, suspender operaciones de escritura hasta conocer el
   impacto antes de modificar datos manualmente.

### Problemas de canjes/puntos

Nunca corregir saldos directamente en PostgreSQL como primera acción.
Conservar:
- user/athlete ID si está disponible por canales internos;
- redemption code;
- correlation ID;
- hora UTC;
- estado observado.

La fuente contable sigue siendo el ledger `point_transactions`.

## Recuperación

Los scripts se encuentran en `scripts/operations`.

- `Backup-Postgres.ps1`
- `Restore-Postgres.ps1`
- `Test-PostgresRestore.ps1`

La contraseña se entrega únicamente mediante `PGPASSWORD` en la sesión de
ejecución. No se guarda en el repositorio.

## Evidencia mínima para cerrar un incidente

- causa identificada;
- hora de inicio y fin;
- servicio afectado;
- correlation IDs representativos;
- acción correctiva;
- verificación de `/health/live` y `/health/ready`;
- si hubo restauración: nombre del backup y resultado del restore drill.
