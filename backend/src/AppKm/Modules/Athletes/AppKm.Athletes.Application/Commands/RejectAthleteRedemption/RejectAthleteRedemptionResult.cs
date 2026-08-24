namespace AppKm.Athletes.Application.Commands.RejectAthleteRedemption;

public sealed record RejectAthleteRedemptionResult(
    Guid RedemptionRequestId,
    string Code,
    string Status,
    DateTimeOffset RejectedAtUtc);