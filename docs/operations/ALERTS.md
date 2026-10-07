# App KM — Política inicial de alertas para piloto

Estas reglas son umbrales iniciales. Deben calibrarse con tráfico real del
piloto; no son SLO definitivos.

## Alertas críticas

### Readiness
Disparar alerta crítica si `/health/ready` permanece no saludable durante
2 minutos consecutivos.

### Disponibilidad
Disparar alerta crítica si `/health/live` no responde durante 2 minutos.

### Errores 5xx
Ventana sugerida: 5 minutos.

- advertencia: tasa 5xx >= 2 % con al menos 20 solicitudes;
- crítica: tasa 5xx >= 5 % con al menos 20 solicitudes.

### Backup
Crítica si no existe un backup exitoso de la base de datos en las últimas
24 horas una vez que el piloto esté operando con datos reales.

## Alertas de advertencia

### Latencia
Advertencia si la latencia promedio permanece por encima de 1000 ms durante
5 minutos. En Sprint 18 debe sustituirse/complementarse con percentiles p95/p99.

### Errores 4xx
No tratarlos automáticamente como fallo del servidor. Revisar aumentos
abruptos, especialmente 401, 403 y 429.

### Restauración
Advertencia si no se ha realizado un restore drill exitoso durante los últimos
30 días.

## Datos necesarios en la alerta

- servicio;
- ambiente;
- hora UTC;
- métrica/health check;
- valor observado;
- correlation ID cuando exista;
- enlace al runbook operativo.
