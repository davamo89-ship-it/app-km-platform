using AppKm.Athletes.Application.Interfaces;
using AppKm.Athletes.Domain.Activities;

namespace AppKm.Athletes.Application.Activities;

public sealed class StravaActivityNormalizer
{
    public NormalizedActivity Normalize(
        StravaActivityResult activity)
    {
        ArgumentNullException.ThrowIfNull(activity);

        AppKmActivityType? activityType =
            StravaSportTypeMapper.Map(
                activity.SportType);

        if (activityType is null)
        {
            throw new InvalidOperationException(
                $"Unsupported Strava sport type: {activity.SportType}");
        }

        double distanceKilometers =
            activity.DistanceMeters / 1000d;

        return new NormalizedActivity(
            activity.Id,
            activityType.Value,
            distanceKilometers,
            activity.StartDateUtc,
            activity.StartDateLocal,
            activity.ElapsedTimeSeconds,
            activity.MovingTimeSeconds);
    }
}