namespace AppKm.Athletes.Domain.Aggregates.Merchants;

public readonly record struct MerchantId(Guid Value)
{
    public static MerchantId New() =>
        new(Guid.NewGuid());
}