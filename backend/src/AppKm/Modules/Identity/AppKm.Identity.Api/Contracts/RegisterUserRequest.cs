namespace AppKm.Identity.Api.Contracts;

public sealed record RegisterUserRequest(
    string Email,
    string Password);