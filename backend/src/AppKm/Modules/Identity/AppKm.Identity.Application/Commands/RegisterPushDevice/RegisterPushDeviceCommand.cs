namespace AppKm.Identity.Application.Commands.RegisterPushDevice;

public sealed record RegisterPushDeviceCommand(
    Guid UserId,
    string Token,
    string Platform);
