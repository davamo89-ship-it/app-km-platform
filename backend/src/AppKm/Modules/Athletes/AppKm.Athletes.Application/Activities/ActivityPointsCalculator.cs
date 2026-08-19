using AppKm.Athletes.Domain.Activities;

namespace AppKm.Athletes.Application.Activities;

public sealed class ActivityPointsCalculator
{
    public int Calculate(
        AppKmActivityType activityType,
        double distanceKilometers)
    {
        if (distanceKilometers < 0)
        {
            throw new ArgumentOutOfRangeException(
                nameof(distanceKilometers));
        }

        return (int)Math.Floor(
            distanceKilometers + 0.5d);
    }
}