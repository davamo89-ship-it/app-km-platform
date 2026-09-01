namespace AppKm.Athletes.Application.Queries.GetLatestMerchantRedemption;

public sealed record GetLatestMerchantRedemptionResult(
    Guid RedemptionRequestId,
    string Code,
    Guid AthleteId,
    string AthleteDisplayName,
    int Points,
    string Status,
    DateTimeOffset CreatedAtUtc,
    DateTimeOffset? MerchantProposedAtUtc,
    DateTimeOffset? CompletedAtUtc);
