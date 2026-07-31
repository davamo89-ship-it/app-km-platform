# App KM Platform

App KM Platform es una plataforma digital multiproducto orientada a transformar actividades deportivas y de bienestar en puntos, beneficios y experiencias de fidelización.

App KM es el primer producto construido sobre la plataforma.

## Estado del proyecto

El proyecto se encuentra actualmente en desarrollo.

### Estado actual

- Sprint 0 — Foundation: completado.
- Sprint 1 — Registro de usuarios: en desarrollo.
- Backend base en .NET 8.
- Arquitectura modular inicial implementada.
- Módulo Identity en desarrollo.
- Aplicación móvil Flutter pendiente de inicialización.
- PostgreSQL y Docker pendientes de configuración.

## Objetivos principales

- Sincronizar actividades desde proveedores deportivos.
- Normalizar y validar actividades.
- Calcular recompensas mediante reglas versionadas.
- Gestionar puntos mediante un Ledger inmutable.
- Mostrar saldos mediante una Wallet proyectada.
- Permitir canjes con comercios y beneficios.
- Soportar múltiples productos y organizaciones.

## Arquitectura

La plataforma utiliza los siguientes principios:

- Domain-Driven Design.
- Modular Monolith.
- Clean Architecture.
- Arquitectura Hexagonal.
- API-first.
- Event-Driven Architecture.
- CQRS selectivo.
- Transactional Outbox.
- Multi-tenancy.
- Configuration-driven development.

## Tecnologías

### Backend

- .NET 8 LTS.
- ASP.NET Core.
- C#.
- Entity Framework Core, pendiente de incorporación.
- PostgreSQL, pendiente de incorporación.

### Mobile

- Flutter.
- Dart.

### Infraestructura

- Docker y Docker Compose.
- GitHub Actions.
- PostgreSQL administrado en futuras etapas.
- OpenTelemetry en futuras etapas.

## Estructura del repositorio

```text
app-km-platform/
├── backend/
│   ├── src/
│   ├── tests/
│   ├── scripts/
│   ├── tools/
│   └── AppKm.sln
├── mobile/
├── infrastructure/
├── docs/
├── scripts/
├── .github/
├── .gitignore
└── README.md