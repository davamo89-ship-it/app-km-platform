using AppKm.Athletes.Application.Interfaces;
using AppKm.Athletes.Domain.Activities;

namespace AppKm.Athletes.Application.Activities;

public sealed class StravaActivityValidator
{
    public ActivityValidationResult Validate(
        StravaActivityResult activity,
        DateTimeOffset now,
        DateTimeOffset? registeredAtUtc = null)
    {
        AppKmActivityType? activityType =
            StravaSportTypeMapper.Map(
                activity.SportType);

        if (activityType is null)
        {
            return ActivityValidationResult.Invalid(
                "UnsupportedSportType");
        }

        if (registeredAtUtc.HasValue &&
            activity.StartDateUtc.ToUniversalTime() < registeredAtUtc.Value.ToUniversalTime())
            return ActivityValidationResult.Invalid("ActivityBeforeAppKmRegistration");

        if (activity.StartDateUtc.ToUniversalTime() > now.ToUniversalTime())
            return ActivityValidationResult.Invalid("ActivityFromFuture");

        if (activity.DistanceMeters < 0)
        {
            return ActivityValidationResult.Invalid(
                "InvalidDistance");
        }

        if (activityType == AppKmActivityType.Cycling &&
            activity.DistanceMeters > 185_000)
        {
            return ActivityValidationResult.Invalid(
                "CyclingDistanceLimitExceeded");
        }

        if (activityType == AppKmActivityType.Running &&
            activity.DistanceMeters > 43_000)
        {
            return ActivityValidationResult.Invalid(
                "RunningDistanceLimitExceeded");
        }

        return ActivityValidationResult.Valid();
    }
}