namespace AppKm.Athletes.Application.Queries.GetPendingRedemptionConfirmation;

public sealed record GetPendingRedemptionConfirmationResult(
    Guid RedemptionRequestId,
    string Code,
    Guid MerchantId,
    string MerchantName,
    int ProposedPoints,
    string Status,
    DateTimeOffset MerchantProposedAtUtc,
    DateTimeOffset ExpiresAtUtc);