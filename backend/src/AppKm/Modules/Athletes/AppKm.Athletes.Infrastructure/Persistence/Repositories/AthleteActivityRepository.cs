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

    public Task<AthleteActivity?> GetLatestAsync(
    AthleteId athleteId,
    CancellationToken cancellationToken)
    {
        return _dbContext.AthleteActivities
            .AsNoTracking()
            .Where(activity =>
                activity.AthleteId == athleteId)
            .OrderByDescending(activity =>
                activity.StartDateUtc)
            .FirstOrDefaultAsync(
                cancellationToken);
    }

    public async Task<IReadOnlyList<AthleteActivity>> GetByAthleteAsync(
    AthleteId athleteId,
    int page,
    int pageSize,
        CancellationToken cancellationToken)
    {
        return await _dbContext.AthleteActivities
            .AsNoTracking()
            .Where(activity =>
                activity.AthleteId == athleteId)
            .OrderByDescending(activity =>
                activity.StartDateUtc)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(cancellationToken);
    }

      public Task<AthleteActivity?> GetByIdAsync(
    Guid activityId,
    CancellationToken cancellationToken)
{
    AthleteActivityId id =
        new(activityId);

    return _dbContext.AthleteActivities
        .AsNoTracking()
        .FirstOrDefaultAsync(
            activity =>
                activity.Id == id,
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