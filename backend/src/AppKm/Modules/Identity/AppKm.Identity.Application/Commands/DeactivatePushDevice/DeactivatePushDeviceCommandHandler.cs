using AppKm.Identity.Application.Interfaces;
using AppKm.Identity.Domain.Aggregates.PushDevices;
using AppKm.Identity.Domain.Aggregates.Users;
using Platform.SharedKernel.Abstractions;

namespace AppKm.Identity.Application.Commands.DeactivatePushDevice;

public sealed class DeactivatePushDeviceCommandHandler
{
    private readonly IPushDeviceRepository _pushDeviceRepository;
    private readonly IUnitOfWork _unitOfWork;
    private readonly IClock _clock;

    public DeactivatePushDeviceCommandHandler(
        IPushDeviceRepository pushDeviceRepository,
        IUnitOfWork unitOfWork,
        IClock clock)
    {
        _pushDeviceRepository = pushDeviceRepository;
        _unitOfWork = unitOfWork;
        _clock = clock;
    }

    public async Task HandleAsync(
        DeactivatePushDeviceCommand command,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(command);
        ArgumentException.ThrowIfNullOrWhiteSpace(command.Token);

        UserId userId = UserId.From(command.UserId);

        PushDevice? pushDevice =
            await _pushDeviceRepository.GetByTokenAsync(
                command.Token.Trim(),
                cancellationToken);

        // El endpoint es idempotente. Si el token ya no existe,
        // ya está inactivo o fue reasignado a otro usuario,
        // no modificamos nada.
        if (pushDevice is null ||
            pushDevice.UserId != userId ||
            !pushDevice.IsActive)
        {
            return;
        }

        pushDevice.Deactivate(_clock.UtcNow);

        await _unitOfWork.SaveChangesAsync(
            cancellationToken);
    }
}
