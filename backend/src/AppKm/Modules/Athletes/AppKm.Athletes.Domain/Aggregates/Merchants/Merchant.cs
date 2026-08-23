using Platform.SharedKernel.Entities;

namespace AppKm.Athletes.Domain.Aggregates.Merchants;

public sealed class Merchant
    : AggregateRoot<MerchantId>
{
    private Merchant()
        : base(default)
    {
        BusinessName = string.Empty;
    }

    private Merchant(
        MerchantId id,
        Guid userId,
        string businessName,
        DateTimeOffset createdAtUtc)
        : base(id)
    {
        UserId = userId;
        BusinessName = businessName;
        Status = MerchantStatus.Active;
        CreatedAtUtc = createdAtUtc;
    }

    public Guid UserId { get; private set; }

    public string BusinessName { get; private set; }

    public MerchantStatus Status { get; private set; }

    public DateTimeOffset CreatedAtUtc { get; private set; }

    public DateTimeOffset? UpdatedAtUtc { get; private set; }

    public static Merchant Create(
        Guid userId,
        string businessName,
        DateTimeOffset createdAtUtc)
    {
        if (userId == Guid.Empty)
        {
            throw new ArgumentException(
                "UserId is required.",
                nameof(userId));
        }

        ArgumentException.ThrowIfNullOrWhiteSpace(
            businessName);

        string normalizedBusinessName =
            businessName.Trim();

        if (normalizedBusinessName.Length > 150)
        {
            throw new ArgumentException(
                "Business name cannot exceed 150 characters.",
                nameof(businessName));
        }

        return new Merchant(
            MerchantId.New(),
            userId,
            normalizedBusinessName,
            createdAtUtc);
    }

    public void UpdateBusinessName(
        string businessName,
        DateTimeOffset updatedAtUtc)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(
            businessName);

        string normalizedBusinessName =
            businessName.Trim();

        if (normalizedBusinessName.Length > 150)
        {
            throw new ArgumentException(
                "Business name cannot exceed 150 characters.",
                nameof(businessName));
        }

        BusinessName = normalizedBusinessName;
        UpdatedAtUtc = updatedAtUtc;
    }

    public void Suspend(
        DateTimeOffset updatedAtUtc)
    {
        Status = MerchantStatus.Suspended;
        UpdatedAtUtc = updatedAtUtc;
    }

    public void Activate(
        DateTimeOffset updatedAtUtc)
    {
        Status = MerchantStatus.Active;
        UpdatedAtUtc = updatedAtUtc;
    }
}
