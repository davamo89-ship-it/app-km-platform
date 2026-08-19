using AppKm.Athletes.Domain.Activities;

namespace AppKm.Athletes.Application.Activities;

public static class StravaSportTypeMapper
{
    public static AppKmActivityType? Map(
        string sportType)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(sportType);

        return sportType switch
        {
            "Ride" => AppKmActivityType.Cycling,
            "MountainBikeRide" => AppKmActivityType.Cycling,
            "GravelRide" => AppKmActivityType.Cycling,
            "VirtualRide" => AppKmActivityType.Cycling,

            "Run" => AppKmActivityType.Running,
            "TrailRun" => AppKmActivityType.Running,
            "VirtualRun" => AppKmActivityType.Running,

            "Walk" => AppKmActivityType.Walking,

            "Swim" => AppKmActivityType.Swimming,

            "WeightTraining" => AppKmActivityType.Gym,
            "Workout" => AppKmActivityType.Gym,

            _ => null
        };
    }
}