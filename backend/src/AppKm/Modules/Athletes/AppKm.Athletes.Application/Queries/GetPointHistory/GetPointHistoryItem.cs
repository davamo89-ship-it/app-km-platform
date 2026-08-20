namespace AppKm.Athletes.Application.Queries.GetPointHistory;

public sealed record GetPointHistoryItem(
    string Type,
    int Points,
    DateTimeOffset CreatedAtUtc,
    DateTimeOffset? ExpiresAtUtc,
    Guid? AthleteActivityId,
    long? StravaActivityId,
    string? ActivityType,
    double? DistanceKilometers);