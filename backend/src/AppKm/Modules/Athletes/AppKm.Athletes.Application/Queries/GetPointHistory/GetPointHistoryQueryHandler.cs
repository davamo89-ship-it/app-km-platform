using AppKm.Athletes.Application.Interfaces;
using AppKm.Athletes.Domain.Aggregates.Athletes;
using Platform.SharedKernel.Errors;
using Platform.SharedKernel.Results;

namespace AppKm.Athletes.Application.Queries.GetPointHistory;

public sealed class GetPointHistoryQueryHandler
{
    private readonly IAthleteRepository _athleteRepository;
    private readonly IPointTransactionRepository _pointTransactionRepository;
    private readonly IAthleteActivityRepository _athleteActivityRepository;

    public GetPointHistoryQueryHandler(
        IAthleteRepository athleteRepository,
        IPointTransactionRepository pointTransactionRepository,
        IAthleteActivityRepository athleteActivityRepository)
    {
        _athleteRepository = athleteRepository;
        _pointTransactionRepository = pointTransactionRepository;
        _athleteActivityRepository = athleteActivityRepository;
    }

    public async Task<Result<IReadOnlyList<GetPointHistoryItem>>> HandleAsync(
        Guid userId,
        CancellationToken cancellationToken)
    {
        Athlete? athlete =
            await _athleteRepository.GetByUserIdAsync(
                userId,
                cancellationToken);

        if (athlete is null)
        {
            return Result<IReadOnlyList<GetPointHistoryItem>>.Failure(
                new Error(
                    "Athletes.Profile.NotFound",
                    "The athlete profile was not found."));
        }

        var transactions =
            await _pointTransactionRepository.GetHistoryAsync(
                athlete.Id.Value,
                cancellationToken);

        var items =
            new List<GetPointHistoryItem>();

        foreach (var transaction in transactions)
        {
            long? stravaActivityId = null;
            string? activityType = null;
            double? distanceKilometers = null;

            if (transaction.AthleteActivityId.HasValue)
            {
                var activity =
                    await _athleteActivityRepository.GetByIdAsync(
                        transaction.AthleteActivityId.Value,
                        cancellationToken);

                if (activity is not null)
                {
                    stravaActivityId =
                        activity.StravaActivityId;

                    activityType =
                        activity.ActivityType.ToString();

                    distanceKilometers =
                        activity.DistanceKilometers;
                }
            }

            items.Add(
                new GetPointHistoryItem(
                    transaction.Type.ToString(),
                    transaction.Points,
                    transaction.CreatedAtUtc,
                    transaction.ExpiresAtUtc,
                    transaction.AthleteActivityId,
                    stravaActivityId,
                    activityType,
                    distanceKilometers));
        }

        return Result<IReadOnlyList<GetPointHistoryItem>>.Success(
            items);
    }
}