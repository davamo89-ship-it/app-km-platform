using AppKm.Identity.Domain.Aggregates.PushDevices;
using AppKm.Identity.Domain.Aggregates.Users;

namespace AppKm.Identity.Application.Interfaces;

public interface IPushDeviceRepository
{
    Task<PushDevice?> GetByTokenAsync(
        string token,
        CancellationToken cancellationToken);

    Task<IReadOnlyCollection<PushDevice>> GetActiveByUserIdAsync(
        UserId userId,
        CancellationToken cancellationToken);

    Task AddAsync(
        PushDevice pushDevice,
        CancellationToken cancellationToken);
}
