namespace AppKm.Athletes.Api.Contracts;

public sealed record StravaConnectionStatusResponse(
    bool Connected,
    long? StravaAthleteId,
    string? Status,
    DateTimeOffset? ConnectedAtUtc,
    DateTimeOffset? AccessTokenExpiresAtUtc);