namespace AppKm.Identity.Api.Contracts;

public sealed record RegisterUserResponse(
    Guid Id,
    string Email);