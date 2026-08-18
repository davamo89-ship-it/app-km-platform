namespace AppKm.Athletes.Application.Interfaces;

public sealed record StravaActivityResult(
    long Id,
    string Name,
    string SportType,
    double DistanceMeters,
    DateTimeOffset StartDateUtc,
    int ElapsedTimeSeconds,
    int MovingTimeSeconds);