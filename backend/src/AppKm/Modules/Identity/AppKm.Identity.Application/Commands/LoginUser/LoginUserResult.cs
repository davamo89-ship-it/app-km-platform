using AppKm.Identity.Domain.Aggregates.Users;

namespace AppKm.Identity.Application.Commands.LoginUser;

public sealed record LoginUserResult(
    UserId UserId,
    string Email,
    string AccessToken,
    DateTimeOffset ExpiresAtUtc);