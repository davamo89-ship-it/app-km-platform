using AppKm.Athletes.Application.Interfaces;
using AppKm.Athletes.Domain.Aggregates.PointTransactions;

namespace AppKm.Athletes.Application.Points;

public sealed class PointExpirationService
{
    private readonly IPointTransactionRepository
        _transactionRepository;

    public PointExpirationService(
        IPointTransactionRepository transactionRepository)
    {
        _transactionRepository =
            transactionRepository;
    }

    public async Task<ExpirePointsResult> ExpireAsync(
    Guid athleteId,
    DateTimeOffset now,
    CancellationToken cancellationToken)
{
    var transactions =
        await _transactionRepository.GetAllByAthleteAsync(
            athleteId,
            cancellationToken);

    var calculator =
        new PointLotCalculator();

    IReadOnlyList<AvailablePointLot> lots =
        calculator.Calculate(transactions);

    int expiredLots = 0;
    int expiredPoints = 0;

    foreach (AvailablePointLot lot in lots)
    {
        if (lot.ExpiresAtUtc > now)
        {
            continue;
        }

        bool alreadyExpired =
            await _transactionRepository
                .ExistsExpiredForActivityAsync(
                    athleteId,
                    lot.AthleteActivityId,
                    cancellationToken);

        if (alreadyExpired)
        {
            continue;
        }

          var expiredTransaction =
                PointTransaction.CreateExpired(
                    athleteId,
                    lot.AthleteActivityId,
                    lot.RemainingPoints,
                    now);

        await _transactionRepository.AddAsync(
            expiredTransaction,
            cancellationToken);

        expiredLots++;
        expiredPoints +=
            lot.RemainingPoints;
    }

    return new ExpirePointsResult(
        expiredLots,
        expiredPoints);
}
}