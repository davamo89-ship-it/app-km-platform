# App KM — Registro y recuperación de contraseña

## Alcance

Este paquete habilita las dos acciones que estaban en modo placeholder en la
pantalla de inicio de sesión:

- Registrar un nuevo usuario atleta.
- Recuperar la contraseña mediante un código de 6 dígitos enviado por correo.

## Decisiones del MVP

### Registro

El backend ya creaba el usuario, asignaba el rol Athlete y aprovisionaba el
perfil de atleta. Sin embargo, el usuario quedaba en `PendingVerification` y no
podía iniciar sesión.

Mientras App KM no tenga un flujo completo de verificación de correo, el
registro del MVP activa la cuenta inmediatamente. Esto evita tener que cambiar
el estado manualmente en PostgreSQL.

Más adelante se puede reemplazar esta activación automática por verificación
real de correo sin cambiar la pantalla de registro.

### Recuperación de contraseña

El flujo es:

1. El usuario ingresa su correo.
2. Identity genera un código criptográficamente aleatorio de 6 dígitos.
3. En la base solamente se guarda SHA-256 del código, nunca el código en claro.
4. El código vence a los 15 minutos.
5. La API siempre responde con un mensaje genérico al solicitar el código para
   no revelar si el correo existe.
6. Al confirmar un código correcto se cambia la contraseña y se invalidan las
   sesiones activas del usuario.
7. El código se elimina del usuario después de utilizarlo.

El endpoint de confirmación está limitado por IP para reducir intentos de fuerza
bruta.

## Endpoints nuevos

### Solicitar código

`POST /api/v1/identity/password-reset/request`

```json
{
  "email": "persona@ejemplo.com"
}
```

Respuesta pública: `202 Accepted`.

### Confirmar recuperación

`POST /api/v1/identity/password-reset/confirm`

```json
{
  "email": "persona@ejemplo.com",
  "code": "123456",
  "newPassword": "NuevaClave1"
}
```

Respuesta exitosa: `204 No Content`.

## Política de contraseña

Se mantiene la política actual de App KM:

- mínimo 8 caracteres;
- al menos una mayúscula;
- al menos una minúscula;
- al menos un número.

## Configuración SMTP

El correo se envía desde Identity API. No se guarda ninguna credencial en Git.

Variables que debe configurar en el ambiente:

```text
Email__SmtpHost
Email__SmtpPort
Email__EnableSsl
Email__Username
Email__Password
Email__FromAddress
Email__FromName
```

Valores típicos:

```text
Email__SmtpPort=587
Email__EnableSsl=true
Email__FromName=App KM
```

`Email__Password` y cualquier credencial SMTP son secretos y deben configurarse
directamente en Render o en el administrador de secretos correspondiente.

Si SMTP no está configurado, Identity seguirá iniciando normalmente. Una
solicitud de recuperación devolverá la respuesta genérica por seguridad, pero el
correo no podrá entregarse; el error quedará en los logs de Identity.

## Migración

La migración nueva agrega tres columnas anulables a `identity.users`:

- `password_reset_code_hash`
- `password_reset_requested_at_utc`
- `password_reset_expires_at_utc`

No modifica contraseñas existentes ni elimina datos.

Migración:

`20261008030000_AddPasswordResetFields`

## Validación recomendada

1. Compilar backend.
2. Ejecutar las pruebas de Identity.
3. Ejecutar `flutter analyze`.
4. Revisar `git diff`.
5. Aplicar la migración a staging.
6. Configurar SMTP en `appkm-identity-staging`.
7. Desplegar.
8. Crear una cuenta nueva desde la app y confirmar que entra al dashboard.
9. Solicitar un código de recuperación.
10. Confirmar que llega por correo.
11. Cambiar la contraseña.
12. Confirmar que la contraseña anterior deja de funcionar y la nueva sí.

No hacer commit hasta completar las validaciones.
