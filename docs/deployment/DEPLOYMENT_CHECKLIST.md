# App KM — Checklist de despliegue

## Antes de desplegar

- [ ] `dotnet build AppKm.sln` correcto.
- [ ] `dotnet test AppKm.sln` correcto.
- [ ] Docker images construyen correctamente.
- [ ] Variables de entorno cargadas en el ambiente.
- [ ] No hay secretos en Git.
- [ ] PostgreSQL de staging es independiente.
- [ ] Backup/restore plan disponible.
- [ ] Migraciones revisadas.
- [ ] Firebase corresponde al ambiente.
- [ ] Callback Strava corresponde al host de staging.

## Después de desplegar

- [ ] Identity `/health/live` = 200.
- [ ] Identity `/health/ready` = 200.
- [ ] Athletes `/health/live` = 200.
- [ ] Athletes `/health/ready` = 200.
- [ ] Login funciona.
- [ ] Refresh token funciona.
- [ ] Dashboard atleta funciona.
- [ ] Conexión Strava funciona.
- [ ] Canje atleta/comercio funciona.
- [ ] SignalR funciona en foreground.
- [ ] FCM funciona en background.
- [ ] Logs muestran correlation IDs.

## Rollback

Si readiness no se recupera o aparecen errores funcionales:

1. detener promoción;
2. volver a la imagen anterior;
3. no revertir migraciones destructivamente sin revisar datos;
4. conservar correlation IDs y logs;
5. seguir `docs/operations/RUNBOOK.md`.
