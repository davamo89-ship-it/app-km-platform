namespace AppKm.Athletes.Application.Commands.ProposeMerchantRedemption;

public sealed record ProposeMerchantRedemptionResult(
    Guid RedemptionRequestId,
    Guid MerchantId,
    string Code,
    int ProposedPoints,
    string Status,
    DateTimeOffset MerchantProposedAtUtc);