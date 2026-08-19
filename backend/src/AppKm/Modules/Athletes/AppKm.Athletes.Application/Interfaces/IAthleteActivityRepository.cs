using AppKm.Athletes.Domain.Aggregates.Athletes;
using AppKm.Athletes.Domain.Aggregates.AthleteActivities;

namespace AppKm.Athletes.Application.Interfaces;

public interface IAthleteActivityRepository
{
    Task<bool> ExistsByStravaActivityIdAsync(
        AthleteId athleteId,
        long stravaActivityId,
        CancellationToken cancellationToken);

    Task AddAsync(
        AthleteActivity activity,
        CancellationToken cancellationToken);
}