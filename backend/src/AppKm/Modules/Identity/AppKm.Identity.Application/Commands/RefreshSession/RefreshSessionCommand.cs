namespace AppKm.Identity.Application.Commands.RefreshSession;

public sealed record RefreshSessionCommand(
    string RefreshToken);