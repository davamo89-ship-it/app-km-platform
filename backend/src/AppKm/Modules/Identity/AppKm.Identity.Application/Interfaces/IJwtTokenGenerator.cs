using AppKm.Identity.Domain.Aggregates.Users;

namespace AppKm.Identity.Application.Interfaces;

public interface IJwtTokenGenerator
{
    JwtTokenResult Generate(
        UserId userId,
        string email);
}

public sealed record JwtTokenResult(
    string AccessToken,
    DateTimeOffset ExpiresAtUtc);