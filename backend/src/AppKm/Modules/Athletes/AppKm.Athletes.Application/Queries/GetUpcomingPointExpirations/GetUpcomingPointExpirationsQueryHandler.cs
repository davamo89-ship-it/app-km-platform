using AppKm.Athletes.Application.Interfaces;
using AppKm.Athletes.Application.Points;
using AppKm.Athletes.Domain.Aggregates.Athletes;
using Platform.SharedKernel.Errors;
using Platform.SharedKernel.Results;

namespace AppKm.Athletes.Application.Queries.GetUpcomingPointExpirations;

public sealed class GetUpcomingPointExpirationsQueryHandler
{
    private static readonly int[] NotificationDays =
    [
        30,
        15,
        7,
        3,
        1
    ];

    private readonly IAthleteRepository _athleteRepository;
    private readonly IPointTransactionRepository
        _pointTransactionRepository;

    private readonly PointLotCalculator _lotCalculator =
        new();

    public GetUpcomingPointExpirationsQueryHandler(
        IAthleteRepository athleteRepository,
        IPointTransactionRepository pointTransactionRepository)
    {
        _athleteRepository = athleteRepository;
        _pointTransactionRepository =
            pointTransactionRepository;
    }

    public async Task<Result<IReadOnlyList<UpcomingPointExpirationItem>>>
        HandleAsync(
            Guid userId,
            DateTimeOffset now,
            CancellationToken cancellationToken)
    {
        Athlete? athlete =
            await _athleteRepository.GetByUserIdAsync(
                userId,
                cancellationToken);

        if (athlete is null)
        {
            return Result<IReadOnlyList<UpcomingPointExpirationItem>>.Failure(
                new Error(
                    "Athletes.Profile.NotFound",
                    "The athlete profile was not found."));
        }

        var transactions =
            await _pointTransactionRepository.GetAllByAthleteAsync(
                athlete.Id.Value,
                cancellationToken);

        IReadOnlyList<AvailablePointLot> lots =
            _lotCalculator.Calculate(
                transactions);

        var result =
            lots
                .Where(lot =>
                    lot.ExpiresAtUtc > now)
                .Select(lot =>
                {
                    int daysRemaining =
                        (int)Math.Ceiling(
                            (lot.ExpiresAtUtc - now)
                                .TotalDays);

                    bool shouldNotify =
                        NotificationDays.Contains(
                            daysRemaining);

                    return new UpcomingPointExpirationItem(
                        lot.RemainingPoints,
                        lot.ExpiresAtUtc,
                        daysRemaining,
                        shouldNotify);
                })
                .OrderBy(item =>
                    item.ExpiresAtUtc)
                .ToList();

        return Result<IReadOnlyList<UpcomingPointExpirationItem>>.Success(
            result);
    }
}