namespace AppKm.Athletes.Application.Interfaces;

public sealed record StravaTokenRefreshResult(
    string AccessToken,
    string RefreshToken,
    DateTimeOffset AccessTokenExpiresAtUtc);