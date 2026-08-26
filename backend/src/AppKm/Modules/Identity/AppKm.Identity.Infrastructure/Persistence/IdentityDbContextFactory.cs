using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace AppKm.Identity.Infrastructure.Persistence;

public sealed class IdentityDbContextFactory
    : IDesignTimeDbContextFactory<IdentityDbContext>
{
    public IdentityDbContext CreateDbContext(
        string[] args)
    {
        var optionsBuilder =
            new DbContextOptionsBuilder<IdentityDbContext>();

        string connectionString =
            Environment.GetEnvironmentVariable(
                "ConnectionStrings__IdentityDatabase")
            ?? "Host=localhost;" +
               "Port=5432;" +
               "Database=appkm;" +
               "Username=appkm;" +
               "Password=appkm";

        optionsBuilder.UseNpgsql(
            connectionString);

        return new IdentityDbContext(
            optionsBuilder.Options);
    }
}