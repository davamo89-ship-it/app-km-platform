namespace AppKm.Identity.Api.Contracts;

public sealed record LogoutSessionRequest(
    string RefreshToken);