using AppKm.Athletes.Application.Interfaces;
using AppKm.Athletes.Domain.Aggregates.Athletes;
using Microsoft.EntityFrameworkCore;

namespace AppKm.Athletes.Infrastructure.Persistence.Repositories;

internal sealed class AthleteRepository
    : IAthleteRepository
{
    private readonly AthleteDbContext _dbContext;

    public AthleteRepository(
        AthleteDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public Task<Athlete?> GetByIdAsync(
        AthleteId athleteId,
        CancellationToken cancellationToken)
    {
        return _dbContext.Athletes
            .SingleOrDefaultAsync(
                athlete => athlete.Id == athleteId,
                cancellationToken);
    }

    public Task<Athlete?> GetByUserIdAsync(
        Guid userId,
        CancellationToken cancellationToken)
    {
        return _dbContext.Athletes
            .SingleOrDefaultAsync(
                athlete => athlete.UserId == userId,
                cancellationToken);
    }

    public Task<bool> ExistsByUserIdAsync(
        Guid userId,
        CancellationToken cancellationToken)
    {
        return _dbContext.Athletes
            .AnyAsync(
                athlete => athlete.UserId == userId,
                cancellationToken);
    }

    public async Task<IReadOnlyList<Athlete>> GetAllAsync(
        CancellationToken cancellationToken)
    {
        return await _dbContext.Athletes
            .AsNoTracking()
            .OrderBy(athlete => athlete.DisplayName)
            .ThenBy(athlete => athlete.CreatedAtUtc)
            .ToListAsync(cancellationToken);
    }

    public async Task AddAsync(
        Athlete athlete,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(athlete);

        await _dbContext.Athletes.AddAsync(
            athlete,
            cancellationToken);
    }
}
