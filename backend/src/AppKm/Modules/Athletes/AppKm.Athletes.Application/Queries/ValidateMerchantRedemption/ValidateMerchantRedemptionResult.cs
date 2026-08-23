namespace AppKm.Athletes.Application.Queries.ValidateMerchantRedemption;

public sealed record ValidateMerchantRedemptionResult(
    Guid RedemptionRequestId,
    string Code,
    int RequestedPoints,
    string Status,
    DateTimeOffset CreatedAtUtc,
    DateTimeOffset ExpiresAtUtc);