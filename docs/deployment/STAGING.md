# App KM — Staging

## Objetivo

Staging es el ambiente previo a producción. Debe usar configuración y datos
separados de Development y Production.

Sprint 19 prepara los artefactos de despliegue, pero no selecciona proveedor
cloud. Las mismas imágenes Docker pueden desplegarse en un servicio compatible
con contenedores.

## Servicios

- Identity API
- Athletes API
- PostgreSQL
- Firebase Admin credentials para Athletes API
- Strava staging/test credentials

## Ambientes

### Development

`ASPNETCORE_ENVIRONMENT=Development`

Usa `appsettings.Development.json` y servicios locales.

### Staging

`ASPNETCORE_ENVIRONMENT=Staging`

Usa `appsettings.Staging.json` más variables de entorno/secrets.

### Production

`ASPNETCORE_ENVIRONMENT=Production`

Usa `appsettings.Production.json` más variables de entorno/secrets.

Los secretos nunca deben vivir dentro de los archivos JSON versionados.

## Imágenes Docker

Desde la raíz del repositorio:

```powershell
.\scripts\deployment\Build-StagingImages.ps1
```

O manualmente:

```powershell
docker build -f backend\Dockerfile.Identity `
  -t appkm-identity-api:staging backend

docker build -f backend\Dockerfile.Athletes `
  -t appkm-athletes-api:staging backend
```

Ambas imágenes escuchan internamente en el puerto `8080`.

## Configuración de reverse proxy

Los contenedores están preparados para operar detrás de un reverse proxy/TLS
terminator.

Configurar:

```text
ASPNETCORE_FORWARDEDHEADERS_ENABLED=true
```

El proxy público debe terminar HTTPS y enviar correctamente
`X-Forwarded-Proto`.

No exponer un staging real directamente por HTTP a Internet.

## Health checks del proveedor

Identity:

```text
/health/live
/health/ready
```

Athletes:

```text
/health/live
/health/ready
```

Usar `/health/live` para liveness y `/health/ready` para readiness.

## Firebase

La cuenta de servicio no se incorpora a la imagen.

Athletes API espera:

```text
GOOGLE_APPLICATION_CREDENTIALS=/run/secrets/firebase-admin.json
```

En un proveedor administrado, preferir el mecanismo de secretos/identidad del
proveedor. El bind mount del compose existe solamente para un staging
autogestionado/local.

## Strava

El callback de staging debe coincidir exactamente con:

```text
https://<ATHLETES_STAGING_HOST>/api/v1/athletes/strava/callback
```

La URL debe registrarse también en la configuración de la aplicación Strava.

## Smoke test

Después del despliegue:

```powershell
.\scripts\deployment\Smoke-Test-Staging.ps1 `
  -IdentityBaseUrl https://identity.staging.example.com `
  -AthletesBaseUrl https://athletes.staging.example.com
```

El smoke test valida liveness y readiness de ambas APIs.

## Promoción a producción

No promover sólo porque el contenedor inicia.

Antes de Production:

1. Backend CI en verde.
2. Deployment Artifacts CI en verde.
3. Migraciones verificadas.
4. `/health/live` y `/health/ready` verdes.
5. Smoke test completo.
6. Backup reciente.
7. Firebase/Strava configurados para el ambiente correcto.
8. JWT secret distinto de Development.
9. Base PostgreSQL separada.
10. URLs de mobile apuntando al ambiente deseado.
