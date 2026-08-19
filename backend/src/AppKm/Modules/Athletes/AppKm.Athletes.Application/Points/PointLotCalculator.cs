using AppKm.Athletes.Domain.Aggregates.PointTransactions;

namespace AppKm.Athletes.Application.Points;

public sealed class PointLotCalculator
{
    public IReadOnlyList<AvailablePointLot> Calculate(
        IReadOnlyList<PointTransaction> transactions)
    {
        ArgumentNullException.ThrowIfNull(transactions);

        var earnedTransactions =
            transactions
                .Where(transaction =>
                    transaction.Type ==
                        PointTransactionType.Earned &&
                    transaction.ExpiresAtUtc.HasValue)
                .OrderBy(transaction =>
                    transaction.ExpiresAtUtc)
                .ToList();

        int consumedPoints =
            transactions
                .Where(transaction =>
                    transaction.Type ==
                        PointTransactionType.Redeemed ||
                    transaction.Type ==
                        PointTransactionType.Expired)
                .Sum(transaction =>
                    transaction.Points);

        var lots =
            new List<AvailablePointLot>();

        foreach (PointTransaction earned in earnedTransactions)
        {
            int remaining =
                earned.Points;

            if (consumedPoints > 0)
            {
                int consumedFromLot =
                    Math.Min(
                        remaining,
                        consumedPoints);

                remaining -=
                    consumedFromLot;

                consumedPoints -=
                    consumedFromLot;
            }

            if (remaining <= 0)
            {
                continue;
            }

          lots.Add(
                new AvailablePointLot(
                    earned.Id.Value,
                    earned.AthleteActivityId!.Value,
                    earned.Points,
                    remaining,
                    earned.CreatedAtUtc,
                    earned.ExpiresAtUtc!.Value));
        }

        return lots;
    }
}