namespace AppKm.Athletes.Infrastructure.Strava;

public sealed class StravaOptions
{
    public const string SectionName = "Strava";

    public string ClientId { get; init; } = string.Empty;

    public string ClientSecret { get; init; } = string.Empty;

    public string RedirectUri { get; init; } = string.Empty;

    public string ApiBaseUrl { get; init; } =
        "https://www.strava.com/api/v3";

    public string OAuthBaseUrl { get; init; } =
        "https://www.strava.com/oauth";
}