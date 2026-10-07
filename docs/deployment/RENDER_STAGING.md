# App KM — Sprint 20: primer staging real en Render

## Arquitectura

El Blueprint `render.yaml` crea:

- `appkm-identity-staging`: Web Service Docker.
- `appkm-athletes-staging`: Web Service Docker.
- `appkm-staging-postgres`: Render Postgres 16.

Los tres recursos se ubican en la misma región.

## Coste inicial

El Blueprint usa plan `free` para esta primera validación de staging.

Esto es sólo para pruebas. El PostgreSQL gratuito de Render expira a los
30 días y no tiene backups administrados. No debe convertirse en producción.

## Configuración automática

Render inyecta host, puerto, nombre de base, usuario y contraseña del PostgreSQL.
`RenderEnvironmentConfiguration` convierte esos valores al formato de
connection string que espera Npgsql.

También usa `RENDER_EXTERNAL_HOSTNAME` para:

- reemplazar `AllowedHosts`;
- construir automáticamente el callback HTTPS de Strava en Athletes.

Por eso no hay dominios `onrender.com` hardcodeados en Git.

## Secretos que Render pedirá

El Blueprint genera un JWT compartido entre ambas APIs.

Debe proporcionar manualmente:

- `Strava__ClientId`
- `Strava__ClientSecret`

Nunca copie estos secretos al repositorio.

## Firebase Admin

Después de crear `appkm-athletes-staging`:

1. Abra el servicio en Render.
2. Environment.
3. Secret Files.
4. Add Secret File.
5. Filename: `firebase-admin.json`.
6. Pegue allí el JSON de la cuenta de servicio.
7. Render lo expondrá en:
   `/etc/secrets/firebase-admin.json`.
8. La variable `GOOGLE_APPLICATION_CREDENTIALS` ya apunta a esa ruta.

No suba ese JSON a ChatGPT, GitHub ni al ZIP del proyecto.

## Migraciones

La primera base de staging es nueva y vacía.

Obtenga en Render los datos de conexión externa y forme una connection string
Npgsql local, por ejemplo:

```text
Host=<host>;Port=<port>;Database=<database>;Username=<user>;Password=<password>;SSL Mode=Require
```

No comparta ese valor.

Ejecute:

```powershell
.\scripts\deployment\render\Invoke-RenderMigrations.ps1 `
  -ConnectionString $env:APPKM_RENDER_DB `
  -ConfirmEmptyStaging
```

La bandera existe para evitar aplicar accidentalmente este procedimiento a
Production o a una base con datos reales.

La migración `20261007030000_FixAthleteActivityLocalTime` requiere especial
cuidado en bases con datos existentes. En el staging nuevo y vacío no existe
conversión de datos históricos.

## Flutter contra staging

No es necesario hardcodear URLs públicas.

Ejecute Flutter con:

```powershell
flutter run -d 138097055K002340 `
  --dart-define=IDENTITY_API_URL=https://<IDENTITY>.onrender.com `
  --dart-define=ATHLETES_API_URL=https://<ATHLETES>.onrender.com `
  --dart-define=STRAVA_AUTH_BACKEND_URL=https://<ATHLETES>.onrender.com `
  --dart-define=STRAVA_REDIRECT_URI=https://<ATHLETES>.onrender.com/api/v1/athletes/strava/callback
```

SignalR usa `ATHLETES_API_URL`, por lo que el hub también pasa al staging
público sin otro cambio de código.

## Strava

En el panel de Strava, registre el host/callback que corresponda al servicio
Athletes de Render:

```text
https://<ATHLETES>.onrender.com/api/v1/athletes/strava/callback
```

El backend seguirá siendo la fuente de verdad del flujo OAuth.

## Validación pública

Después de migraciones y Firebase:

```powershell
.\scripts\deployment\render\Smoke-Test-RenderStaging.ps1 `
  -IdentityBaseUrl https://<IDENTITY>.onrender.com `
  -AthletesBaseUrl https://<ATHLETES>.onrender.com
```

Después haga la prueba funcional en este orden:

1. registro/login;
2. refresh;
3. perfil/dashboard;
4. conexión Strava;
5. sincronización;
6. canje atleta/comercio;
7. SignalR foreground;
8. FCM background/terminated.

## Antes de producción

No promover el plan gratuito a Production.

Production requiere como mínimo:

- PostgreSQL persistente con backups;
- servicios sin spin-down;
- plan de rollback;
- secretos propios de Production;
- dominio definitivo;
- smoke test y prueba funcional completos.
