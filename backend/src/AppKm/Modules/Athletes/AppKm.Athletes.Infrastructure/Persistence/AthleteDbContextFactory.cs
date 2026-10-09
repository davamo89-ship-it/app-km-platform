using System.Data.Common;
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

        string connectionString =
            Environment.GetEnvironmentVariable(
                "ConnectionStrings__AthleteDatabase")
            ?? BuildManagedPostgresConnectionString()
            ?? "Host=localhost;" +
               "Port=5432;" +
               "Database=appkm;" +
               "Username=appkm;" +
               "Password=appkm";

        optionsBuilder.UseNpgsql(
            connectionString);

        return new AthleteDbContext(
            optionsBuilder.Options);
    }

    private static string? BuildManagedPostgresConnectionString()
    {
        string? host = Environment.GetEnvironmentVariable("RENDER_POSTGRES_HOST");
        string? port = Environment.GetEnvironmentVariable("RENDER_POSTGRES_PORT");
        string? database = Environment.GetEnvironmentVariable("RENDER_POSTGRES_DATABASE");
        string? username = Environment.GetEnvironmentVariable("RENDER_POSTGRES_USER");
        string? password = Environment.GetEnvironmentVariable("RENDER_POSTGRES_PASSWORD");

        if (string.IsNullOrWhiteSpace(host) ||
            string.IsNullOrWhiteSpace(port) ||
            string.IsNullOrWhiteSpace(database) ||
            string.IsNullOrWhiteSpace(username) ||
            string.IsNullOrWhiteSpace(password) ||
            !int.TryParse(port, out int parsedPort))
        {
            return null;
        }

        var builder = new DbConnectionStringBuilder
        {
            ["Host"] = host,
            ["Port"] = parsedPort,
            ["Database"] = database,
            ["Username"] = username,
            ["Password"] = password,
            ["SSL Mode"] = "Prefer",
            ["Timeout"] = 15,
            ["Command Timeout"] = 30
        };

        return builder.ConnectionString;
    }
}
