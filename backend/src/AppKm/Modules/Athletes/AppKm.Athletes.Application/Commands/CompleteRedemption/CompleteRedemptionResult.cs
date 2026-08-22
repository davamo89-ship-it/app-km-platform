namespace AppKm.Athletes.Application.Commands.CompleteRedemption;

public sealed record CompleteRedemptionResult(
    Guid RedemptionRequestId,
    string Code,
    int RedeemedPoints,
    string Status,
    DateTimeOffset CompletedAtUtc);