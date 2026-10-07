using System.Data.Common;
using Microsoft.Extensions.Configuration;

namespace Platform.SharedKernel.Configuration;

public static class RenderEnvironmentConfiguration
{
    public static void Apply(
        IConfiguration configuration,
        bool configureStravaRedirect = false)
    {
        ArgumentNullException.ThrowIfNull(configuration);

        string? renderHost =
            configuration["RENDER_EXTERNAL_HOSTNAME"];

        if (!string.IsNullOrWhiteSpace(renderHost))
        {
            string? allowedHosts =
                configuration["AllowedHosts"];

            if (string.IsNullOrWhiteSpace(allowedHosts) ||
                allowedHosts.Trim() == "*" ||
                allowedHosts.StartsWith(
                    "REPLACE_",
                    StringComparison.OrdinalIgnoreCase))
            {
                configuration["AllowedHosts"] =
                    renderHost;
            }

            if (configureStravaRedirect)
            {
                string? redirectUri =
                    configuration["Strava:RedirectUri"];

                if (string.IsNullOrWhiteSpace(redirectUri) ||
                    redirectUri.Contains(
                        "REPLACE_",
                        StringComparison.OrdinalIgnoreCase))
                {
                    configuration["Strava:RedirectUri"] =
                        $"https://{renderHost}/api/v1/athletes/strava/callback";
                }
            }
        }

        ApplyPostgresConnectionStrings(configuration);
    }

    private static void ApplyPostgresConnectionStrings(
        IConfiguration configuration)
    {
        if (!string.IsNullOrWhiteSpace(
                configuration.GetConnectionString("IdentityDatabase")) &&
            !string.IsNullOrWhiteSpace(
                configuration.GetConnectionString("AthleteDatabase")))
        {
            return;
        }

        string? host =
            configuration["RENDER_POSTGRES_HOST"];

        string? port =
            configuration["RENDER_POSTGRES_PORT"];

        string? database =
            configuration["RENDER_POSTGRES_DATABASE"];

        string? username =
            configuration["RENDER_POSTGRES_USER"];

        string? password =
            configuration["RENDER_POSTGRES_PASSWORD"];

        if (string.IsNullOrWhiteSpace(host) ||
            string.IsNullOrWhiteSpace(port) ||
            string.IsNullOrWhiteSpace(database) ||
            string.IsNullOrWhiteSpace(username) ||
            string.IsNullOrWhiteSpace(password))
        {
            return;
        }

        if (!int.TryParse(
                port,
                out int parsedPort))
        {
            throw new InvalidOperationException(
                "RENDER_POSTGRES_PORT must be a valid integer.");
        }

        var builder =
            new DbConnectionStringBuilder
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

        string connectionString =
            builder.ConnectionString;

        if (string.IsNullOrWhiteSpace(
                configuration.GetConnectionString("IdentityDatabase")))
        {
            configuration["ConnectionStrings:IdentityDatabase"] =
                connectionString;
        }

        if (string.IsNullOrWhiteSpace(
                configuration.GetConnectionString("AthleteDatabase")))
        {
            configuration["ConnectionStrings:AthleteDatabase"] =
                connectionString;
        }
    }
}
