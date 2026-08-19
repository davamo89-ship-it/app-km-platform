namespace AppKm.Athletes.Application.Points;

public sealed record AvailablePointLot(
    Guid TransactionId,
    Guid AthleteActivityId,
    int OriginalPoints,
    int RemainingPoints,
    DateTimeOffset EarnedAtUtc,
    DateTimeOffset ExpiresAtUtc);