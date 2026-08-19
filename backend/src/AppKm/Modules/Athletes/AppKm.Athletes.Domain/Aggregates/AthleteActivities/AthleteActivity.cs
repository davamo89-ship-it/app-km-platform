using AppKm.Athletes.Domain.Activities;
using AppKm.Athletes.Domain.Aggregates.Athletes;
using Platform.SharedKernel.Entities;

namespace AppKm.Athletes.Domain.Aggregates.AthleteActivities;

public sealed class AthleteActivity
    : AggregateRoot<AthleteActivityId>
{
    private AthleteActivity()
        : base(default)
    {
    }

    private AthleteActivity(
        AthleteActivityId id,
        AthleteId athleteId,
        long stravaActivityId,
        AppKmActivityType activityType,
        double distanceKilometers,
        int points,
        DateTimeOffset startDateUtc,
        DateTime startDateLocal,
        int elapsedTimeSeconds,
        int movingTimeSeconds,
        DateTimeOffset createdAtUtc)
        : base(id)
    {
        AthleteId = athleteId;
        StravaActivityId = stravaActivityId;
        ActivityType = activityType;
        DistanceKilometers = distanceKilometers;
        Points = points;
        StartDateUtc = startDateUtc;
        StartDateLocal = startDateLocal;
        ElapsedTimeSeconds = elapsedTimeSeconds;
        MovingTimeSeconds = movingTimeSeconds;
        CreatedAtUtc = createdAtUtc;
        
    }

    public AthleteId AthleteId { get; private set; }

    public long StravaActivityId { get; private set; }

    public AppKmActivityType ActivityType { get; private set; }

    public double DistanceKilometers { get; private set; }

    public int Points { get; private set; }

    public DateTimeOffset StartDateUtc { get; private set; }

    public DateTime StartDateLocal { get; private set; }

    public int ElapsedTimeSeconds { get; private set; }

    public int MovingTimeSeconds { get; private set; }

    public DateTimeOffset CreatedAtUtc { get; private set; }
    

    public static AthleteActivity Create(
        AthleteId athleteId,
        long stravaActivityId,
        AppKmActivityType activityType,
        double distanceKilometers,
        int points,
        DateTimeOffset startDateUtc,
        DateTime startDateLocal,
        int elapsedTimeSeconds,
        int movingTimeSeconds,
        DateTimeOffset createdAtUtc)
    {
        if (stravaActivityId <= 0)
        {
            throw new ArgumentOutOfRangeException(
                nameof(stravaActivityId));
        }

        if (distanceKilometers < 0)
        {
            throw new ArgumentOutOfRangeException(
                nameof(distanceKilometers));
        }

        return new AthleteActivity(
            AthleteActivityId.New(),
            athleteId,
            stravaActivityId,
            activityType,
            distanceKilometers,
            points,
            startDateUtc,
            startDateLocal,
            elapsedTimeSeconds,
            movingTimeSeconds,
            createdAtUtc);
    }
}