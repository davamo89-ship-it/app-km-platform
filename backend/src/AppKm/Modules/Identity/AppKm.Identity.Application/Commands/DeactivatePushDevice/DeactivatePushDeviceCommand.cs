namespace AppKm.Identity.Application.Commands.DeactivatePushDevice;

public sealed record DeactivatePushDeviceCommand(
    Guid UserId,
    string Token);
