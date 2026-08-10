namespace AppKm.Athletes.Application.Commands.DisconnectStrava;

public sealed record DisconnectStravaCommand(
    Guid UserId);