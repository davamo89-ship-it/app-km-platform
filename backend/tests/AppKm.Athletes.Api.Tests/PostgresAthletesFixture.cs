using AppKm.Athletes.Infrastructure.DependencyInjection;
using AppKm.Athletes.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Testcontainers.PostgreSql;
using Xunit;

namespace AppKm.Athletes.Api.Tests;

public sealed class PostgresAthletesFixture
    : IAsyncLifetime
{
    private readonly PostgreSqlContainer _postgres =
        new PostgreSqlBuilder("postgres:16-alpine")
            .WithDatabase("appkm_test")
            .WithUsername("appkm")
            .WithPassword("appkm")
            .Build();

    public ServiceProvider Services { get; private set; } = null!;

    public async Task InitializeAsync()
    {
        await _postgres.StartAsync();

        var values =
            new Dictionary<string, string?>
            {
                ["ConnectionStrings:AthleteDatabase"] =
                    _postgres.GetConnectionString(),
                ["ConnectionStrings:IdentityDatabase"] =
                    _postgres.GetConnectionString(),
                ["Jwt:Issuer"] = "AppKm.Integration.Tests",
                ["Jwt:Audience"] = "AppKm.Integration.Tests",
                ["Jwt:Secret"] =
                    "TEST_ONLY_SECRET_123456789012345678901234567890",
                ["Firebase:ProjectId"] = "app-km-tests",
                ["Strava:ClientId"] = "12345",
                ["Strava:ClientSecret"] = "test-client-secret",
                ["Strava:RedirectUri"] =
                    "https://localhost/api/v1/athletes/strava/callback"
            };

        IConfiguration configuration =
            new ConfigurationBuilder()
                .AddInMemoryCollection(values)
                .Build();

        var services =
            new ServiceCollection();

        services.AddLogging();
        services.AddAthleteInfrastructure(
            configuration);

        Services =
            services.BuildServiceProvider();

        await using AsyncServiceScope scope =
            Services.CreateAsyncScope();

        AthleteDbContext dbContext =
            scope.ServiceProvider
                .GetRequiredService<AthleteDbContext>();

        await dbContext.Database.MigrateAsync();
    }

    public async Task ResetAsync()
    {
        await using AsyncServiceScope scope =
            Services.CreateAsyncScope();

        AthleteDbContext dbContext =
            scope.ServiceProvider
                .GetRequiredService<AthleteDbContext>();

        await dbContext.Database.ExecuteSqlRawAsync(
            """
            TRUNCATE TABLE
                athletes.point_transactions,
                athletes.redemption_requests,
                athletes.athlete_activities,
                athletes.merchants,
                athletes.strava_connections,
                athletes.athletes
            RESTART IDENTITY CASCADE;
            """);
    }

    public async Task DisposeAsync()
    {
        await Services.DisposeAsync();
        await _postgres.DisposeAsync();
    }
}
