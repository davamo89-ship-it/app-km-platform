# App KM — Registro y recuperación de contraseña

## Envío de recuperación por Resend HTTPS

App KM envía los códigos de recuperación mediante la API HTTPS de Resend.
Esto evita depender de puertos SMTP salientes y funciona con el tráfico HTTPS
normal del servicio de staging.

El flujo de recuperación se mantiene sin cambios:

1. Identity genera un código criptográficamente aleatorio de 6 dígitos.
2. Solo guarda SHA-256 del código en PostgreSQL.
3. El código vence a los 15 minutos.
4. Identity llama a `https://api.resend.com/emails` por HTTPS.
5. Al confirmar el código se cambia la contraseña y se invalidan las sesiones.

## Variables de entorno

Configurar directamente en Render para `appkm-identity-staging`:

```text
Email__ApiKey=<secreto de Resend>
Email__ApiBaseUrl=https://api.resend.com
Email__FromAddress=onboarding@resend.dev
Email__FromName=App KM
```

`Email__ApiKey` es secreto y nunca debe guardarse en Git, documentación,
capturas ni archivos de configuración versionados.

Para la primera prueba se puede usar `onboarding@resend.dev`, remitente de
prueba de Resend. Para producción, reemplazarlo por una dirección de un dominio
propio verificado en Resend.

Las variables SMTP antiguas (`Email__SmtpHost`, `Email__SmtpPort`, etc.) ya no
son utilizadas por el sender registrado en Identity y pueden eliminarse de
Render después de validar el flujo HTTPS.

## Validación

1. `dotnet build`.
2. Ejecutar las cuatro suites de pruebas actuales.
3. Desplegar el hotfix.
4. Configurar `Email__ApiKey` y el remitente en Render.
5. Solicitar un código desde la app.
6. Revisar Resend > Logs si la entrega no ocurre.
7. Confirmar el código y cambiar la contraseña.
8. Validar que la contraseña anterior deje de funcionar y la nueva sí.
