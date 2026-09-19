using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using Microsoft.Extensions.Options;

namespace AppKm.Athletes.Api.Tests;

public sealed class AthletesApiFactory : WebApplicationFactory<Program>
{
    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Development");

        builder.ConfigureAppConfiguration(
            (_, configuration) =>
            {
                var values =
                    new Dictionary<string, string?>
                    {
                        ["ConnectionStrings:AthleteDatabase"] =
                            "Host=localhost;Port=5433;Database=appkm_test;Username=appkm;Password=appkm",
                        ["ConnectionStrings:IdentityDatabase"] =
                            "Host=localhost;Port=5433;Database=appkm_test;Username=appkm;Password=appkm",
                        ["Jwt:Issuer"] = "AppKm.Athletes.Api.Tests",
                        ["Jwt:Audience"] = "AppKm.Platform.Tests",
                        ["Jwt:Secret"] =
                            "TEST_ONLY_SECRET_123456789012345678901234567890",
                        ["Firebase:ProjectId"] = "app-km-tests",
                        ["Strava:ClientId"] = "12345",
                        ["Strava:ClientSecret"] = "test-client-secret",
                        ["Strava:RedirectUri"] =
                            "https://localhost/api/v1/athletes/strava/callback"
                    };

                configuration.AddInMemoryCollection(values);
            });

        builder.ConfigureServices(
            services =>
            {
                services.PostConfigure<HealthCheckServiceOptions>(
                    options =>
                    {
                        options.Registrations.Clear();

                        options.Registrations.Add(
                            new HealthCheckRegistration(
                                "test-health",
                                _ => new AlwaysHealthyCheck(),
                                HealthStatus.Unhealthy,
                                tags: null));
                    });
            });
    }

    private sealed class AlwaysHealthyCheck : IHealthCheck
    {
        public Task<HealthCheckResult> CheckHealthAsync(
            HealthCheckContext context,
            CancellationToken cancellationToken = default)
        {
            return Task.FromResult(
                HealthCheckResult.Healthy("Test host is healthy."));
        }
    }
}
