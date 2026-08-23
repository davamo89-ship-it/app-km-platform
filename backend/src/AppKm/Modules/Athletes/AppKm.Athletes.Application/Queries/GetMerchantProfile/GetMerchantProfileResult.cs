namespace AppKm.Athletes.Application.Queries.GetMerchantProfile;

public sealed record GetMerchantProfileResult(
    Guid MerchantId,
    Guid UserId,
    string BusinessName,
    string Status,
    DateTimeOffset CreatedAtUtc,
    DateTimeOffset? UpdatedAtUtc);