using AppKm.Athletes.Application.Interfaces;
using AppKm.Athletes.Domain.Aggregates.Athletes;
using Platform.SharedKernel.Errors;
using Platform.SharedKernel.Results;
namespace AppKm.Athletes.Application.Queries.GetAthleteActivities;

public sealed class GetAthleteActivitiesQueryHandler
{
    private readonly IAthleteRepository _athleteRepository;
    private readonly IAthleteActivityRepository _activityRepository;

    public GetAthleteActivitiesQueryHandler(
        IAthleteRepository athleteRepository,
        IAthleteActivityRepository activityRepository)
    {
        _athleteRepository = athleteRepository;
        _activityRepository = activityRepository;
    }

    public async Task<Result<IReadOnlyList<GetAthleteActivityItem>>> HandleAsync(
        Guid userId,
        int page,
        int pageSize,
        CancellationToken cancellationToken)
    {
        if (page < 1)
        {
            page = 1;
        }

        if (pageSize < 1)
        {
            pageSize = 20;
        }

        if (pageSize > 100)
        {
            pageSize = 100;
        }

        Athlete? athlete =
            await _athleteRepository.GetByUserIdAsync(
                userId,
                cancellationToken);

        if (athlete is null)
        {
            return Result<IReadOnlyList<GetAthleteActivityItem>>.Failure(
                new Error(
                    "Athletes.Profile.NotFound",
                    "The athlete profile was not found."));
        }

        var activities =
            await _activityRepository.GetByAthleteAsync(
                athlete.Id,
                page,
                pageSize,
                cancellationToken);

        var items =
            activities
                .Select(activity =>
                    new GetAthleteActivityItem(
                        activity.StravaActivityId,
                        activity.ActivityType.ToString(),
                        activity.DistanceKilometers,
                        activity.Points,
                        activity.StartDateUtc,
                        activity.StartDateLocal,
                        activity.ElapsedTimeSeconds,
                        activity.MovingTimeSeconds))
                .ToList();

        return Result<IReadOnlyList<GetAthleteActivityItem>>.Success(
            items);
    }
}