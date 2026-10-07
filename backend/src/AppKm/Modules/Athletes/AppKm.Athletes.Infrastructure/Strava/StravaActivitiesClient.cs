using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json.Serialization;
using AppKm.Athletes.Application.Interfaces;
using Microsoft.AspNetCore.WebUtilities;
using Microsoft.Extensions.Options;

namespace AppKm.Athletes.Infrastructure.Strava;

internal sealed class StravaActivitiesClient
    : IStravaActivitiesClient
{
    private readonly HttpClient _httpClient;
    private readonly StravaOptions _options;

    public StravaActivitiesClient(
        HttpClient httpClient,
        IOptions<StravaOptions> options)
    {
        _httpClient = httpClient;
        _options = options.Value;
    }

    public async Task<IReadOnlyList<StravaActivityResult>> GetActivitiesAsync(
        string accessToken,
        DateTimeOffset? after,
        DateTimeOffset? before,
        int page,
        int perPage,
        CancellationToken cancellationToken)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(accessToken);

        string endpoint =
            $"{_options.ApiBaseUrl.TrimEnd('/')}/athlete/activities";

        var query = new Dictionary<string, string?>
        {
            ["page"] = page.ToString(),
            ["per_page"] = perPage.ToString()
        };

        if (after.HasValue)
        {
            query["after"] =
                after.Value.ToUnixTimeSeconds().ToString();
        }

        if (before.HasValue)
        {
            query["before"] =
                before.Value.ToUnixTimeSeconds().ToString();
        }

        string url =
            QueryHelpers.AddQueryString(
                endpoint,
                query);

        using var request =
            new HttpRequestMessage(
                HttpMethod.Get,
                url);

        request.Headers.Authorization =
            new AuthenticationHeaderValue(
                "Bearer",
                accessToken);

        using HttpResponseMessage response =
            await _httpClient.SendAsync(
                request,
                cancellationToken);

        response.EnsureSuccessStatusCode();

        List<StravaActivityResponse>? activities =
            await response.Content
                .ReadFromJsonAsync<List<StravaActivityResponse>>(
                    cancellationToken:
                        cancellationToken);

        if (activities is null)
        {
            return [];
        }

        return activities
            .Select(activity =>
                new StravaActivityResult(
                    activity.Id,
                    activity.Name,
                    activity.SportType,
                    activity.Distance,
                    activity.StartDate,
                    activity.StartDateLocal,
                    activity.ElapsedTime,
                    activity.MovingTime,
                    activity.Manual,
                    activity.Flagged,
                    activity.AverageSpeed,
                    activity.MaxSpeed,
                    activity.TotalElevationGain,
                    activity.ElevationHigh,
                    activity.ElevationLow,
                    activity.HasHeartRate,
                    activity.DeviceWatts,
                    activity.AverageWatts,
                    activity.AverageHeartRate,
                    activity.AverageCadence,
                    activity.DeviceName,
                    activity.Trainer,
                    activity.UploadId,
                    activity.ExternalId))
            .ToList();
    }

    private sealed record StravaActivityResponse(
        [property: JsonPropertyName("id")]
        long Id,

        [property: JsonPropertyName("name")]
        string Name,

        [property: JsonPropertyName("sport_type")]
        string SportType,

        [property: JsonPropertyName("distance")]
        double Distance,

        [property: JsonPropertyName("start_date")]
        DateTimeOffset StartDate,

        [property: JsonPropertyName("start_date_local")]
        DateTime StartDateLocal,

        [property: JsonPropertyName("elapsed_time")]
        int ElapsedTime,

        [property: JsonPropertyName("moving_time")]
        int MovingTime,

        [property: JsonPropertyName("manual")]
        bool Manual,

        [property: JsonPropertyName("flagged")]
        bool Flagged,

        [property: JsonPropertyName("average_speed")]
        double? AverageSpeed,

        [property: JsonPropertyName("max_speed")]
        double? MaxSpeed,

        [property: JsonPropertyName("total_elevation_gain")]
        double? TotalElevationGain,

        [property: JsonPropertyName("elev_high")]
        double? ElevationHigh,

        [property: JsonPropertyName("elev_low")]
        double? ElevationLow,

        [property: JsonPropertyName("has_heartrate")]
        bool HasHeartRate,

        [property: JsonPropertyName("device_watts")]
        bool DeviceWatts,

        [property: JsonPropertyName("average_watts")]
        double? AverageWatts,

        [property: JsonPropertyName("average_heartrate")]
        double? AverageHeartRate,

        [property: JsonPropertyName("average_cadence")]
        double? AverageCadence,

        [property: JsonPropertyName("device_name")]
        string? DeviceName,

        [property: JsonPropertyName("trainer")]
        bool Trainer,

        [property: JsonPropertyName("upload_id")]
        long? UploadId,

        [property: JsonPropertyName("external_id")]
        string? ExternalId);
}
