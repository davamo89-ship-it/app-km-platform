namespace AppKm.Athletes.Application.Commands.ConfirmAthleteRedemption;

public sealed record ConfirmAthleteRedemptionResult(
    Guid RedemptionRequestId,
    Guid MerchantId,
    string Code,
    int RedeemedPoints,
    string Status,
    DateTimeOffset AthleteConfirmedAtUtc,
    DateTimeOffset CompletedAtUtc);
