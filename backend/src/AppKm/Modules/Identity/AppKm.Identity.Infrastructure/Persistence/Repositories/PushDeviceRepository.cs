using AppKm.Identity.Application.Interfaces;
using AppKm.Identity.Domain.Aggregates.PushDevices;
using AppKm.Identity.Domain.Aggregates.Users;
using Microsoft.EntityFrameworkCore;

namespace AppKm.Identity.Infrastructure.Persistence.Repositories;

internal sealed class PushDeviceRepository
    : IPushDeviceRepository
{
    private readonly IdentityDbContext _dbContext;

    public PushDeviceRepository(
        IdentityDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public Task<PushDevice?> GetByTokenAsync(
        string token,
        CancellationToken cancellationToken)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(token);

        string normalizedToken = token.Trim();

        return _dbContext.PushDevices
            .SingleOrDefaultAsync(
                pushDevice =>
                    pushDevice.Token == normalizedToken,
                cancellationToken);
    }

    public async Task<IReadOnlyCollection<PushDevice>>
        GetActiveByUserIdAsync(
            UserId userId,
            CancellationToken cancellationToken)
    {
        return await _dbContext.PushDevices
            .Where(pushDevice =>
                pushDevice.UserId == userId &&
                pushDevice.IsActive)
            .OrderByDescending(pushDevice =>
                pushDevice.UpdatedAtUtc)
            .ToListAsync(cancellationToken);
    }

    public async Task AddAsync(
        PushDevice pushDevice,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(pushDevice);

        await _dbContext.PushDevices.AddAsync(
            pushDevice,
            cancellationToken);
    }
}
