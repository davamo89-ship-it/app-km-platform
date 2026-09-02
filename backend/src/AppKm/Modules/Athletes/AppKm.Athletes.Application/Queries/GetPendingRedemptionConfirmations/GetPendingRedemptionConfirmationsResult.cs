namespace AppKm.Athletes.Application.Queries.GetPendingRedemptionConfirmations;

public sealed record GetPendingRedemptionConfirmationsResult(
    Guid RedemptionRequestId,
    string Code,
    Guid MerchantId,
    string MerchantName,
    int ProposedPoints,
    string Status,
    DateTimeOffset MerchantProposedAtUtc,
    DateTimeOffset ExpiresAtUtc);
