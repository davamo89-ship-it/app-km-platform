namespace AppKm.Athletes.Application.Commands.ConnectStrava;

public sealed record ConnectStravaCommand(
    Guid UserId,
    string AuthorizationCode);