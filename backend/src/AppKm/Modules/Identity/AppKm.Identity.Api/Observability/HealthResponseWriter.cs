using Microsoft.AspNetCore.Diagnostics.HealthChecks;
using Microsoft.Extensions.Diagnostics.HealthChecks;

namespace AppKm.Identity.Api.Observability;

internal static class HealthResponseWriter
{
    public static Task WriteAsync(
        HttpContext context,
        HealthReport report)
    {
        context.Response.ContentType =
            "application/json; charset=utf-8";

        var body =
            new
            {
                status =
                    report.Status.ToString(),
                totalDurationMilliseconds =
                    Math.Round(
                        report.TotalDuration.TotalMilliseconds,
                        3),
                checks =
                    report.Entries
                        .OrderBy(entry => entry.Key)
                        .ToDictionary(
                            entry => entry.Key,
                            entry => new
                            {
                                status =
                                    entry.Value.Status.ToString(),
                                durationMilliseconds =
                                    Math.Round(
                                        entry.Value.Duration.TotalMilliseconds,
                                        3),
                                description =
                                    entry.Value.Description
                            })
            };

        return context.Response.WriteAsJsonAsync(
            body);
    }
}
