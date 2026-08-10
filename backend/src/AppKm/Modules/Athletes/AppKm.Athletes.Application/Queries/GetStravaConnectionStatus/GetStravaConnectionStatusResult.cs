namespace AppKm.Athletes.Application.Queries.GetStravaConnectionStatus;

public sealed record GetStravaConnectionStatusResult(
    bool Connected,
    long? StravaAthleteId,
    string? Status,
    DateTimeOffset? ConnectedAtUtc,
    DateTimeOffset? AccessTokenExpiresAtUtc);