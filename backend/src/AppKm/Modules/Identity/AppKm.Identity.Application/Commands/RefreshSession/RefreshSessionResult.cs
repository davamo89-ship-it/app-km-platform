namespace AppKm.Identity.Application.Commands.RefreshSession;

public sealed record RefreshSessionResult(
    Guid UserId,
    string Email,
    string AccessToken,
    DateTimeOffset AccessTokenExpiresAtUtc,
    string RefreshToken,
    DateTimeOffset RefreshTokenExpiresAtUtc);