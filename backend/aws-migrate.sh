#!/usr/bin/env bash
set -euo pipefail

echo "Applying Identity migrations..."
dotnet ef database update \
  --project src/AppKm/Modules/Identity/AppKm.Identity.Infrastructure/AppKm.Identity.Infrastructure.csproj \
  --startup-project src/AppKm/Modules/Identity/AppKm.Identity.Api/AppKm.Identity.Api.csproj \
  --context AppKm.Identity.Infrastructure.Persistence.IdentityDbContext

echo "Applying Athletes migrations..."
dotnet ef database update \
  --project src/AppKm/Modules/Athletes/AppKm.Athletes.Infrastructure/AppKm.Athletes.Infrastructure.csproj \
  --startup-project src/AppKm/Modules/Athletes/AppKm.Athletes.Api/AppKm.Athletes.Api.csproj \
  --context AppKm.Athletes.Infrastructure.Persistence.AthleteDbContext

echo "AWS staging migrations completed."
