namespace AppKm.Identity.Api.Contracts;

public sealed record LoginUserResponse(
    Guid UserId,
    string Email,
    string AccessToken,
    DateTimeOffset ExpiresAtUtc);