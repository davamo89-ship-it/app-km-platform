namespace AppKm.Athletes.Domain.Aggregates.PointTransactions;

public readonly record struct PointTransactionId(Guid Value)
{
    public static PointTransactionId New()
    {
        return new PointTransactionId(Guid.NewGuid());
    }
}