# App KM - Guía de Desarrollo

## Objetivo

Este documento describe el flujo estándar para desarrollar la plataforma App KM.

---

# Requisitos

- Windows 11
- Visual Studio Code
- .NET SDK 8
- Flutter
- Docker Desktop
- PostgreSQL (contenedor Docker)
- Git

---

# Inicio de la jornada

## 1. Abrir Docker Desktop

Esperar que indique:

Engine running

---

## 2. Abrir VS Code

Abrir la carpeta raíz:

C:\Projects\app-km

---

## 3. Levantar PostgreSQL

```powershell
docker compose -f infrastructure\docker\compose\docker-compose.yml up -d
```

Verificar:

```powershell
docker compose -f infrastructure\docker\compose\docker-compose.yml ps
```

Debe aparecer:

```
appkm-postgres
Status: healthy
```

---

## 4. Ejecutar la API

```powershell
cd backend

dotnet run --project src\AppKm\Modules\Identity\AppKm.Identity.Api\AppKm.Identity.Api.csproj

dotnet run --project src\AppKm\Modules\Athletes\AppKm.Athletes.Api\AppKm.Athletes.Api.csproj
```

---

## 5. Abrir Swagger

```
http://localhost:5264/swagger
```

---

# Antes de comenzar

Actualizar repositorio

```powershell
git pull
```

---

# Al terminar

Guardar cambios

```powershell
git add .

git commit -m "mensaje"

git push
```

---

# Migraciones EF

Agregar migración

```powershell
dotnet tool run dotnet-ef migrations add NombreMigracion
```

Actualizar base

```powershell
dotnet tool run dotnet-ef database update
```

---

# Docker

Levantar servicios

```powershell
docker compose up -d
```

Detener servicios

```powershell
docker compose down
```

Ver contenedores

```powershell
docker ps
```

---

# Arquitectura

Platform

- SharedKernel

Modules

- Identity
- Athlete
- Commerce
- Rewards
- Administration

Cada módulo contiene:

- Api
- Application
- Domain
- Infrastructure

---

# Convenciones

Cada nueva funcionalidad deberá incluir:

- Domain
- Application
- Infrastructure
- Api
- Swagger
- Validaciones
- Pruebas manuales
- Commit
- Push

# Sprint 3 — Authentication

## Completed

- User registration
- User login
- BCrypt password hashing
- JWT authentication
- Protected endpoints
- Refresh Token
- Refresh Token Rotation
- Logout
- Session Revocation

Status: ✅ Completed