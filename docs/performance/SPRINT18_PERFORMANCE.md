# Sprint 18 — Performance, índices y carga

## Optimización aplicada

Este sprint evita optimización especulativa. Los índices agregados corresponden
a consultas que ya existen en el código.

### athlete_activities

`(athlete_id, start_date_utc)`

Soporta:
- última actividad del atleta;
- actividades paginadas ordenadas por fecha;
- historial usado por dashboard/antifraude.

### point_transactions

`(athlete_id, type)`

Soporta:
- cálculo del saldo por tipo de transacción;
- validaciones de ledger por atleta.

`(athlete_id, created_at_utc)`

Soporta:
- historial cronológico de puntos;
- carga de lotes por atleta.

### redemption_requests

`(athlete_id, created_at_utc)`

Soporta:
- historial de canjes del atleta.

`(athlete_id, status, expires_at_utc)`

Soporta:
- puntos reservados;
- solicitudes pendientes/confirmación;
- expiración de solicitudes.

`(merchant_id, merchant_proposed_at_utc, created_at_utc)`

Soporta:
- último canje de comercio;
- historial de comercio.

## Cambios de consultas

- `GetBalanceAsync` pasa de 3 consultas SUM a un solo agregado SQL.
- los historiales de `PointTransaction` son `AsNoTracking`.
- consultas de historial/listado de canjes por comercio son `AsNoTracking`.
- Dashboard elimina una consulta redundante a `GetLatestAsync`; toma la última
  actividad de la lista ya ordenada.

No se cambió lógica funcional de puntos, antifraude ni canjes.

## Prueba de carga

Script:

`scripts/performance/Invoke-AppKmLoadTest.ps1`

Ejemplo sin autenticación:

```powershell
.\scripts\performance\Invoke-AppKmLoadTest.ps1 `
  -Url http://localhost:5208/health/live `
  -Requests 500 `
  -Concurrency 20
```

Ejemplo autenticado:

```powershell
.\scripts\performance\Invoke-AppKmLoadTest.ps1 `
  -Url http://localhost:5208/api/v1/athletes/dashboard `
  -Requests 200 `
  -Concurrency 10 `
  -BearerToken $env:APPKM_TEST_TOKEN
```

No guardar tokens en scripts.

## Baseline inicial sugerido para piloto

Estas cifras son criterios de observación, no garantía contractual:

- fallos: 0 % en endpoints saludables;
- p95:
  - health/live < 250 ms local;
  - endpoints de lectura comunes < 1000 ms local;
- ningún 5xx bajo carga moderada;
- vigilar 429: puede ser esperado en endpoints rate-limited.

Los resultados locales no sustituyen pruebas en staging. Sprint posterior debe
repetir la carga en infraestructura equivalente a producción.

## Qué no se hizo

- no se agregaron índices a todas las columnas;
- no se cambió el modelo de ledger;
- no se introdujo caché;
- no se añadió Redis;
- no se cambió la semántica de endpoints;
- no se hizo tuning de PostgreSQL específico de proveedor/hosting.
