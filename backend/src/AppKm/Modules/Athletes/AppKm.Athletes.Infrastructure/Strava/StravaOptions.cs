namespace AppKm.Athletes.Infrastructure.Strava;

public sealed class StravaOptions
{
    public const string SectionName = "Strava";

    public int ClientId { get; init; }

    public string ClientSecret { get; init; } = string.Empty;

    public string RedirectUri { get; init; } = string.Empty;
}