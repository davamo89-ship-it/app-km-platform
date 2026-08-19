using AppKm.Athletes.Domain.Activities;

namespace AppKm.Athletes.Application.Activities;

public sealed record NormalizedActivity(
    long StravaActivityId,
    AppKmActivityType ActivityType,
    double DistanceKilometers,
    DateTimeOffset StartDateUtc,
    DateTime StartDateLocal,
    int ElapsedTimeSeconds,
    int MovingTimeSeconds);