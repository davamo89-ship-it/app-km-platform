namespace AppKm.Athletes.Application.Commands.RejectAthleteRedemption;

public sealed record RejectAthleteRedemptionResult(
    Guid RedemptionRequestId,
    Guid MerchantId,
    string Code,
    string Status,
    DateTimeOffset RejectedAtUtc);
