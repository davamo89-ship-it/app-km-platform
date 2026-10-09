# App KM — AWS Migration Master

## Objetivo

Centralizar staging y posteriormente producción en AWS, retirando Render y Resend después de validar paridad funcional.

## Arquitectura incluida

- Amazon Cognito User Pool + Identity Pool.
- Grupos `Athlete`, `Merchant`, `Admin`.
- Confirmación de correo y recuperación de contraseña por Cognito.
- RDS PostgreSQL 16 privado.
- Amazon ECS Express Mode sobre Fargate para Identity y Athletes.
- ECR para las tres imágenes: Identity, Athletes y Migrations.
- ECS Express Mode crea y administra el Application Load Balancer, TLS/ACM, auto scaling y una URL HTTPS `*.ecs.<region>.on.aws` por servicio.
- No se requiere CloudFront para staging; esto evita que la verificación específica de CloudFront bloquee el despliegue.
- Secrets Manager para PostgreSQL, JWT de compatibilidad y Strava.
- Amazon SNS como capa backend de push; FCM sigue siendo el último transporte Android.
- CloudWatch Logs y Container Insights.
- S3 privado/versionado preparado para almacenamiento futuro.

## Autenticación

En AWS, Flutter usa Amplify Auth + Cognito. Los endpoints antiguos de login/reset se conservan temporalmente solo como compatibilidad de código y no forman parte del flujo móvil AWS.

Cognito emite un `sub` externo. Durante esta etapa, el backend deriva de forma determinística un `Guid` interno de App KM a partir del subject validado y mantiene el contrato actual de los controllers. El primer login llama `POST /api/v1/identity/provision-cognito`, crea la cuenta local de dominio y sincroniza los roles observados en `cognito:groups`.

Esta estrategia es válida para el staging AWS nuevo. No debe utilizarse para migrar producción con usuarios existentes sin diseñar primero un mapa explícito de identidades.

## Datos de staging

El RDS AWS debe considerarse un staging nuevo. Se aplican las migraciones EF actuales desde un contenedor Fargate especializado. No se copia automáticamente la información de prueba de Render.

## Ejecución

Desde la raíz del repositorio, después de copiar este paquete:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\aws\Deploy-AppKmAws.ps1
```

El script realiza foundation, secretos de Strava, SNS/FCM si encuentra `C:\AppKmSecrets\firebase-admin.json`, build/push ECR, migraciones Fargate, despliegue ECS y genera el launcher Flutter.

## Seguridad

Nunca pegue en ChatGPT ni versiona credenciales AWS, URL/clave de RDS, Strava Client Secret, Firebase service account ni claves privadas. AWS CLI obtiene credenciales desde el perfil/sesión del equipo y los secretos se escriben directamente en Secrets Manager/SNS.

## SES

El User Pool usa inicialmente el correo administrado por Cognito para que el despliegue no dependa de un dominio. Para producción, verifique un dominio o dirección en SES, solicite salida del sandbox y vuelva a desplegar pasando `SesSourceArn` y `SesFromAddress` al stack. Resend ya no es necesario para el flujo Cognito.

## Costos y staging

Este staging usa una instancia RDS `db.t4g.micro`, dos servicios ECS Express Mode/Fargate cuando el compute está activo y ALB/TLS administrado por ECS Express Mode. AWS puede generar cargos aun con poco tráfico. Configure AWS Budgets/alertas de costos en la cuenta antes de dejar recursos encendidos indefinidamente.

## Corte de Render

No elimine Render todavía. El corte se hace únicamente cuando se hayan validado en AWS: registro/confirmación, login, recuperación, perfil, Strava, sincronización, puntos, canjes, SignalR foreground, SNS/FCM background/terminated y roles.

## V5 — migration-task hardening

The Fargate migration task receives the RDS endpoint, port, database and username directly from CloudFormation and only the password through Secrets Manager. The two EF design-time factories can build the Npgsql connection string from those managed environment values, so `dotnet ef database update` does not fall back to localhost inside AWS.


## AWS Free Plan - staging

Mientras la cuenta esté en AWS Free Plan, el RDS de staging usa 1 día de retención de backups automáticos y no habilita autoscaling de almacenamiento. Esto evita el límite que AWS aplica al Free Plan y también evita crecimiento de almacenamiento no planificado. Para Production se debe definir una política de backup mayor después de pasar al Paid Plan.


## V8 — ECS Express Mode HTTPS

CloudFront deja de ser dependencia de staging. AWS ECS Express Mode crea para cada API una URL HTTPS administrada con certificado TLS y Application Load Balancer, manteniendo Fargate y CloudWatch. Identity y Athletes conservan URLs separadas, igual que la configuración Flutter original. El ALB subyacente soporta WebSockets, por lo que SignalR puede continuar usando la URL de Athletes.

Endpoints esperados:

- `https://appkm-staging-identity.ecs.us-east-1.on.aws`
- `https://appkm-staging-athletes.ecs.us-east-1.on.aws`

El callback de Strava apunta al endpoint HTTPS de Athletes. CloudFront puede habilitarse más adelante si AWS completa la verificación de cuenta y existe una razón concreta para usar CDN/edge.
