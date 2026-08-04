namespace AppKm.Identity.Api.Contracts;

public sealed record LoginUserRequest(
    string Email,
    string Password);