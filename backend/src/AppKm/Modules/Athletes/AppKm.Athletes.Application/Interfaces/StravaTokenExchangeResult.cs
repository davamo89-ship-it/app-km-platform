namespace AppKm.Athletes.Application.Interfaces;

public sealed record StravaTokenExchangeResult(
    long StravaAthleteId,
    string AccessToken,
    string RefreshToken,
    DateTimeOffset AccessTokenExpiresAtUtc);