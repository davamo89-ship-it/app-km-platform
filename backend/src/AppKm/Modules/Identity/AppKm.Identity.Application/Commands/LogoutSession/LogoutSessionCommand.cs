namespace AppKm.Identity.Application.Commands.LogoutSession;

public sealed record LogoutSessionCommand(
    string RefreshToken);