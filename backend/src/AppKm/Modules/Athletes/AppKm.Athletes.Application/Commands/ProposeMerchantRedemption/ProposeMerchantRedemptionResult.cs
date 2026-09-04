namespace AppKm.Athletes.Application.Commands.ProposeMerchantRedemption;

public sealed record ProposeMerchantRedemptionResult(
    Guid RedemptionRequestId,
    Guid MerchantId,
    Guid AthleteId,
    string Code,
    int ProposedPoints,
    string Status,
    DateTimeOffset MerchantProposedAtUtc);
