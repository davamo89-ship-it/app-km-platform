namespace AppKm.Athletes.Domain.Aggregates.RedemptionRequests;

public readonly record struct RedemptionRequestId(Guid Value)
{
    public static RedemptionRequestId New() =>
        new(Guid.NewGuid());
}