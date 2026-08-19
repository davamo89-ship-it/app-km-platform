using AppKm.Athletes.Application.Interfaces;
using AppKm.Athletes.Domain.Activities;

namespace AppKm.Athletes.Application.Activities;

public sealed class StravaActivityValidator
{
    public ActivityValidationResult Validate(
        StravaActivityResult activity,
        DateTimeOffset now)
    {
        AppKmActivityType? activityType =
            StravaSportTypeMapper.Map(
                activity.SportType);

        if (activityType is null)
        {
            return ActivityValidationResult.Invalid(
                "UnsupportedSportType");
        }

        DateOnly activityDate =
            DateOnly.FromDateTime(
                activity.StartDateLocal);

        DateOnly currentDate =
            DateOnly.FromDateTime(
                now.DateTime);

        if (activityDate != currentDate)
        {
            return ActivityValidationResult.Invalid(
                "ActivityNotFromCurrentDay");
        }

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