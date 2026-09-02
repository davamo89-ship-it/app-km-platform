namespace AppKm.Athletes.Application.Queries.GetMerchantRedemptionHistory;

public sealed record GetMerchantRedemptionHistoryResult(
    Guid RedemptionRequestId,
    string Code,
    Guid AthleteId,
    string AthleteDisplayName,
    int Points,
    string Status,
    DateTimeOffset CreatedAtUtc,
    DateTimeOffset? MerchantProposedAtUtc,
    DateTimeOffset? CompletedAtUtc);
