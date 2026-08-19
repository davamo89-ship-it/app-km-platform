namespace AppKm.Athletes.Domain.Aggregates.AthleteActivities;

public readonly record struct AthleteActivityId(Guid Value)
{
    public static AthleteActivityId New() =>
        new(Guid.NewGuid());
}