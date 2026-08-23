namespace AppKm.Athletes.Application.Commands.CancelRedemption;

public sealed record CancelRedemptionResult(
    Guid RedemptionRequestId,
    string Code,
    string Status);
