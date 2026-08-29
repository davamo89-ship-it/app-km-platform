using AppKm.Athletes.Domain.Aggregates.Athletes;
using AppKm.Athletes.Domain.Aggregates.AthleteActivities;

namespace AppKm.Athletes.Application.Interfaces;

public interface IAthleteActivityRepository
{
    Task<bool> ExistsByStravaActivityIdAsync(
        AthleteId athleteId,
        long stravaActivityId,
        CancellationToken cancellationToken);

    Task<AthleteActivity?> GetLatestAsync(
        AthleteId athleteId,
        CancellationToken cancellationToken);

    Task<IReadOnlyList<AthleteActivity>> GetAllByAthleteAsync(
        AthleteId athleteId,
        CancellationToken cancellationToken);


    Task<IReadOnlyList<AthleteActivity>> GetByAthleteAsync(
        AthleteId athleteId,
        int page,
        int pageSize,
        CancellationToken cancellationToken);

    Task<AthleteActivity?> GetByIdAsync(
        Guid activityId,
        CancellationToken cancellationToken);

    Task AddAsync(
        AthleteActivity activity,
        CancellationToken cancellationToken);
}