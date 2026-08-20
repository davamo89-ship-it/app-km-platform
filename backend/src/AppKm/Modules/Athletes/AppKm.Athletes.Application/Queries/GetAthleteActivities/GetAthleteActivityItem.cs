namespace AppKm.Athletes.Application.Queries.GetAthleteActivities;

public sealed record GetAthleteActivityItem(
    long StravaActivityId,
    string ActivityType,
    double DistanceKilometers,
    int Points,
    DateTimeOffset StartDateUtc,
    DateTime StartDateLocal,
    int ElapsedTimeSeconds,
    int MovingTimeSeconds);