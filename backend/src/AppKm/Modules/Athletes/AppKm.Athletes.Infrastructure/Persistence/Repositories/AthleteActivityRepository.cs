using AppKm.Athletes.Application.Interfaces;
using AppKm.Athletes.Domain.Aggregates.AthleteActivities;
using AppKm.Athletes.Domain.Aggregates.Athletes;
using Microsoft.EntityFrameworkCore;

namespace AppKm.Athletes.Infrastructure.Persistence.Repositories;

internal sealed class AthleteActivityRepository
    : IAthleteActivityRepository
{
    private readonly AthleteDbContext _dbContext;

    public AthleteActivityRepository(
        AthleteDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public Task<bool> ExistsByStravaActivityIdAsync(
        AthleteId athleteId,
        long stravaActivityId,
        CancellationToken cancellationToken)
    {
        return _dbContext.AthleteActivities
            .AnyAsync(
                activity =>
                    activity.AthleteId == athleteId &&
                    activity.StravaActivityId == stravaActivityId,
                cancellationToken);
    }

    public async Task AddAsync(
        AthleteActivity activity,
        CancellationToken cancellationToken)
    {
        await _dbContext.AthleteActivities.AddAsync(
            activity,
            cancellationToken);
    }
}