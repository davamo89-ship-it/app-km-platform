namespace AppKm.Athletes.Application.Queries.GetUpcomingPointExpirations;

public sealed record UpcomingPointExpirationItem(
    int RemainingPoints,
    DateTimeOffset ExpiresAtUtc,
    int DaysRemaining,
    bool ShouldNotify);