using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace AppKm.Athletes.Infrastructure.Persistence;

public sealed class AthleteDbContextFactory
    : IDesignTimeDbContextFactory<AthleteDbContext>
{
    public AthleteDbContext CreateDbContext(
        string[] args)
    {
        var optionsBuilder =
            new DbContextOptionsBuilder<AthleteDbContext>();

        const string connectionString =
            "Host=localhost;" +
            "Port=5432;" +
            "Database=appkm;" +
            "Username=appkm;" +
            "Password=appkm";

        optionsBuilder.UseNpgsql(
            connectionString);

        return new AthleteDbContext(
            optionsBuilder.Options);
    }
}