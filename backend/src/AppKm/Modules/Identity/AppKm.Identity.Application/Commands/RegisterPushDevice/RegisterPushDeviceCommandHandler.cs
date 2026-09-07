using AppKm.Identity.Application.Interfaces;
using AppKm.Identity.Domain.Aggregates.PushDevices;
using AppKm.Identity.Domain.Aggregates.Users;
using Platform.SharedKernel.Abstractions;

namespace AppKm.Identity.Application.Commands.RegisterPushDevice;

public sealed class RegisterPushDeviceCommandHandler
{
    private readonly IPushDeviceRepository _pushDeviceRepository;
    private readonly IUnitOfWork _unitOfWork;
    private readonly IClock _clock;

    public RegisterPushDeviceCommandHandler(
        IPushDeviceRepository pushDeviceRepository,
        IUnitOfWork unitOfWork,
        IClock clock)
    {
        _pushDeviceRepository = pushDeviceRepository;
        _unitOfWork = unitOfWork;
        _clock = clock;
    }

    public async Task HandleAsync(
        RegisterPushDeviceCommand command,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(command);

        UserId userId = UserId.From(command.UserId);

        PushDevice? existing =
            await _pushDeviceRepository.GetByTokenAsync(
                command.Token.Trim(),
                cancellationToken);

        DateTimeOffset utcNow = _clock.UtcNow;

        if (existing is null)
        {
            PushDevice pushDevice = PushDevice.Create(
                PushDeviceId.New(),
                userId,
                command.Token,
                command.Platform,
                utcNow);

            await _pushDeviceRepository.AddAsync(
                pushDevice,
                cancellationToken);
        }
        else
        {
            existing.RegisterForUser(
                userId,
                command.Platform,
                utcNow);
        }

        await _unitOfWork.SaveChangesAsync(
            cancellationToken);
    }
}
