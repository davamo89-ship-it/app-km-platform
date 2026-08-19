namespace AppKm.Athletes.Application.Interfaces;

public sealed record StravaActivityResult(
    long Id,
    string Name,
    string SportType,
    double DistanceMeters,
    DateTimeOffset StartDateUtc,
    DateTime StartDateLocal,
    int ElapsedTimeSeconds,
    int MovingTimeSeconds);