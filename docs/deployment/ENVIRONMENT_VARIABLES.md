# App KM — Variables de entorno para despliegue

## Compartidas

| Variable | Identity | Athletes | Secreto |
|---|---|---|---|
| `ASPNETCORE_ENVIRONMENT` | Sí | Sí | No |
| `ASPNETCORE_HTTP_PORTS` | Sí | Sí | No |
| `ASPNETCORE_FORWARDEDHEADERS_ENABLED` | Sí | Sí | No |
| `AllowedHosts` | Sí | Sí | No |
| `ConnectionStrings__IdentityDatabase` | Sí | Sí | Sí |
| `ConnectionStrings__AthleteDatabase` | Sí | Sí | Sí |
| `Jwt__Issuer` | Sí | Sí | No |
| `Jwt__Audience` | Sí | Sí | No |
| `Jwt__Secret` | Sí | Sí | Sí |

## Identity

- `Jwt__ExpirationMinutes`
- `RefreshToken__ExpirationDays`
- `RefreshToken__SizeInBytes`

## Athletes

- `Firebase__ProjectId`
- `GOOGLE_APPLICATION_CREDENTIALS` cuando se usa archivo de service account
- `Strava__ClientId`
- `Strava__ClientSecret`
- `Strava__RedirectUri`

## Reglas

- `Jwt__Secret` debe tener al menos 32 bytes UTF-8.
- Development, Staging y Production deben usar secretos distintos.
- Las connection strings nunca deben versionarse con credenciales reales.
- El archivo Firebase no se agrega a Git ni a la imagen Docker.
- Staging y Production deben usar bases de datos separadas.
