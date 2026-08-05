namespace AppKm.Identity.Api.Contracts;

public sealed record RefreshSessionRequest(
    string RefreshToken);