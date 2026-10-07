using AppKm.Athletes.Application.Interfaces;
using AppKm.Athletes.Domain.Activities;
using AppKm.Athletes.Domain.Aggregates.AthleteActivities;

namespace AppKm.Athletes.Application.Activities;

/// <summary>
/// Pilot anti-fraud policy for Strava activities.
///
/// This evaluator intentionally uses conservative plausibility thresholds.
/// Extreme-but-human performances are sent to Review instead of being
/// automatically rejected whenever the available evidence is insufficient.
///
/// The thresholds are not sporting records. They are safety margins whose
/// purpose is to reject clearly impossible activity and hold suspicious
/// activity without punishing legitimate high-performance athletes.
/// </summary>
public sealed class ActivityFraudEvaluator
{
    private const int ReviewRiskThreshold = 35;
    private const int InvalidRiskThreshold = 85;
    private const int StrongManualEvidenceThreshold = 75;
    private const int MinimumHistoryCount = 5;

    public ActivityFraudAssessment Evaluate(
        StravaActivityResult activity,
        AppKmActivityType activityType,
        IReadOnlyList<AthleteActivity> history)
    {
        ArgumentNullException.ThrowIfNull(activity);
        ArgumentNullException.ThrowIfNull(history);

        var reasons = new List<string>();

        int evidenceScore =
            CalculateEvidenceScore(
                activity,
                activityType);

        if (activity.Manual &&
            evidenceScore < StrongManualEvidenceThreshold)
        {
            reasons.Add("ManualActivityInsufficientEvidence");

            return new ActivityFraudAssessment(
                ActivityFraudStatus.Ineligible,
                evidenceScore,
                100,
                reasons);
        }

        double distanceKilometers =
            activity.DistanceMeters / 1000d;

        double averageSpeedKmh =
            GetAverageSpeedKmh(activity);

        double maxSpeedKmh =
            Math.Max(
                0d,
                (activity.MaxSpeedMetersPerSecond ?? 0d) * 3.6d);

        if (RequiresDistance(activityType) &&
            distanceKilometers > 0 &&
            activity.MovingTimeSeconds <= 0)
        {
            reasons.Add("DistanceWithoutMovingTime");

            return new ActivityFraudAssessment(
                ActivityFraudStatus.Invalid,
                evidenceScore,
                100,
                reasons);
        }

        ActivityFraudAssessment? impossible =
            EvaluateImpossiblePerformance(
                activity,
                activityType,
                distanceKilometers,
                averageSpeedKmh,
                maxSpeedKmh,
                evidenceScore);

        if (impossible is not null)
        {
            return impossible;
        }

        int riskScore = 0;

        if (activity.Flagged)
        {
            riskScore += 60;
            reasons.Add("FlaggedByStrava");
        }

        if (activity.Manual)
        {
            riskScore += 10;
            reasons.Add("ManualActivityWithStrongEvidence");
        }

        riskScore +=
            EvaluateSportSpecificRisk(
                activity,
                activityType,
                distanceKilometers,
                averageSpeedKmh,
                evidenceScore,
                reasons);

        riskScore +=
            EvaluateHistoricalRisk(
                activityType,
                distanceKilometers,
                averageSpeedKmh,
                history,
                reasons);

        riskScore =
            Math.Clamp(
                riskScore,
                0,
                100);

        ActivityFraudStatus status =
            riskScore >= InvalidRiskThreshold
                ? ActivityFraudStatus.Invalid
                : riskScore >= ReviewRiskThreshold
                    ? ActivityFraudStatus.Review
                    : ActivityFraudStatus.Valid;

        return new ActivityFraudAssessment(
            status,
            evidenceScore,
            riskScore,
            reasons);
    }

    private static int CalculateEvidenceScore(
        StravaActivityResult activity,
        AppKmActivityType activityType)
    {
        int score = 0;

        if (!activity.Manual)
        {
            score += 20;
        }

        if (activity.UploadId is > 0 ||
            !string.IsNullOrWhiteSpace(activity.ExternalId))
        {
            score += 10;
        }

        if (!string.IsNullOrWhiteSpace(activity.DeviceName))
        {
            score += 20;
        }

        if (activity.AverageSpeedMetersPerSecond is >= 0)
        {
            score += 10;
        }

        if (activity.MaxSpeedMetersPerSecond is >= 0)
        {
            score += 5;
        }

        if (activity.TotalElevationGainMeters is >= 0 &&
            activityType is
                AppKmActivityType.Cycling or
                AppKmActivityType.Running or
                AppKmActivityType.Walking)
        {
            score += 10;
        }

        if (activity.HasHeartRate ||
            activity.AverageHeartRate is > 0)
        {
            score += 15;
        }

        if (activityType == AppKmActivityType.Cycling &&
            activity.DeviceWatts &&
            activity.AverageWatts is > 0)
        {
            score += 20;
        }

        if (activity.AverageCadence is > 0)
        {
            score += 10;
        }

        if (activity.Trainer)
        {
            score += 5;
        }

        return Math.Clamp(score, 0, 100);
    }

    private static ActivityFraudAssessment? EvaluateImpossiblePerformance(
        StravaActivityResult activity,
        AppKmActivityType activityType,
        double distanceKilometers,
        double averageSpeedKmh,
        double maxSpeedKmh,
        int evidenceScore)
    {
        string? reason = null;

        switch (activityType)
        {
            case AppKmActivityType.Walking:
                if (distanceKilometers >= 1 &&
                    averageSpeedKmh > 22)
                {
                    reason = "WalkingAverageSpeedImpossible";
                }
                else if (distanceKilometers >= 1 &&
                         maxSpeedKmh > 45)
                {
                    reason = "WalkingMaxSpeedImpossible";
                }

                break;

            case AppKmActivityType.Running:
                if (distanceKilometers >= 1 &&
                    averageSpeedKmh > 32)
                {
                    reason = "RunningAverageSpeedImpossible";
                }
                else if (distanceKilometers >= 1 &&
                         maxSpeedKmh > 60)
                {
                    reason = "RunningMaxSpeedImpossible";
                }

                break;

            case AppKmActivityType.Cycling:
                if (distanceKilometers >= 5 &&
                    averageSpeedKmh > 110)
                {
                    reason = "CyclingAverageSpeedImpossible";
                }
                else if (distanceKilometers >= 5 &&
                         maxSpeedKmh > 170)
                {
                    reason = "CyclingMaxSpeedImpossible";
                }

                break;

            case AppKmActivityType.Swimming:
                if (distanceKilometers >= 0.2 &&
                    averageSpeedKmh > 9)
                {
                    reason = "SwimmingAverageSpeedImpossible";
                }

                break;

            case AppKmActivityType.Gym:
                if (activity.ElapsedTimeSeconds > 8 * 60 * 60)
                {
                    reason = "GymDurationImplausible";
                }

                break;
        }

        if (reason is null)
        {
            return null;
        }

        return new ActivityFraudAssessment(
            ActivityFraudStatus.Invalid,
            evidenceScore,
            100,
            new[] { reason });
    }

    private static int EvaluateSportSpecificRisk(
        StravaActivityResult activity,
        AppKmActivityType activityType,
        double distanceKilometers,
        double averageSpeedKmh,
        int evidenceScore,
        ICollection<string> reasons)
    {
        int risk = 0;

        switch (activityType)
        {
            case AppKmActivityType.Walking:
                if (distanceKilometers >= 1 &&
                    averageSpeedKmh > 16.5)
                {
                    risk += 45;
                    reasons.Add("WalkingEliteRangeExceeded");
                }
                else if (distanceKilometers >= 1 &&
                         averageSpeedKmh > 13)
                {
                    risk += 20;
                    reasons.Add("WalkingHighSpeed");
                }

                break;

            case AppKmActivityType.Running:
                if (distanceKilometers >= 1 &&
                    averageSpeedKmh > 26)
                {
                    risk += 60;
                    reasons.Add("RunningExtremeSpeed");
                }
                else if (distanceKilometers >= 3 &&
                         averageSpeedKmh > 23)
                {
                    risk += 30;
                    reasons.Add("RunningEliteSpeed");
                }

                break;

            case AppKmActivityType.Cycling:
                risk +=
                    EvaluateCyclingRisk(
                        activity,
                        distanceKilometers,
                        averageSpeedKmh,
                        evidenceScore,
                        reasons);

                break;

            case AppKmActivityType.Swimming:
                if (distanceKilometers >= 0.2 &&
                    averageSpeedKmh > 6.8)
                {
                    risk += 55;
                    reasons.Add("SwimmingExtremeSpeed");
                }
                else if (distanceKilometers >= 0.5 &&
                         averageSpeedKmh > 5.5)
                {
                    risk += 20;
                    reasons.Add("SwimmingEliteSpeed");
                }

                break;

            case AppKmActivityType.Gym:
                if (activity.ElapsedTimeSeconds < 5 * 60)
                {
                    risk += 35;
                    reasons.Add("GymDurationTooShort");
                }

                break;
        }

        return risk;
    }

    private static int EvaluateCyclingRisk(
        StravaActivityResult activity,
        double distanceKilometers,
        double averageSpeedKmh,
        int evidenceScore,
        ICollection<string> reasons)
    {
        if (distanceKilometers < 5)
        {
            return 0;
        }

        int risk = 0;

        if (averageSpeedKmh > 90)
        {
            risk += 75;
            reasons.Add("CyclingVeryExtremeAverageSpeed");
        }
        else if (averageSpeedKmh > 75)
        {
            risk += 55;
            reasons.Add("CyclingExtremeAverageSpeed");
        }
        else if (averageSpeedKmh > 60)
        {
            risk += 35;
            reasons.Add("CyclingVeryHighAverageSpeed");
        }
        else if (averageSpeedKmh > 50)
        {
            risk += 20;
            reasons.Add("CyclingHighAverageSpeed");
        }

        double elevationRange =
            Math.Max(
                0d,
                (activity.ElevationHighMeters ?? 0d) -
                (activity.ElevationLowMeters ?? 0d));

        // A large elevation range is compatible with a long descent.
        // It does not prove that the rider descended, so it reduces
        // suspicion but never overrides an impossible-speed rule.
        if (averageSpeedKmh > 50 &&
            elevationRange >= 1_000)
        {
            risk -= 25;
            reasons.Add("LargeElevationRangeSupportsDescent");
        }

        bool nearlyFlat =
            (activity.TotalElevationGainMeters ?? 0d) <=
            Math.Max(100d, distanceKilometers * 5d);

        if (distanceKilometers >= 15 &&
            averageSpeedKmh >= 45 &&
            nearlyFlat &&
            evidenceScore < 50)
        {
            risk += 25;
            reasons.Add("HighFlatCyclingSpeedWithWeakEvidence");
        }

        if (distanceKilometers >= 15 &&
            averageSpeedKmh >= 50 &&
            evidenceScore >= 70)
        {
            risk -= 10;
            reasons.Add("StrongTelemetrySupportsCyclingPerformance");
        }

        return Math.Max(0, risk);
    }

    private static int EvaluateHistoricalRisk(
        AppKmActivityType activityType,
        double distanceKilometers,
        double averageSpeedKmh,
        IReadOnlyList<AthleteActivity> history,
        ICollection<string> reasons)
    {
        AthleteActivity[] sameSport =
            history
                .Where(item =>
                    item.ActivityType == activityType &&
                    item.DistanceKilometers > 0 &&
                    item.MovingTimeSeconds > 0)
                .ToArray();

        if (sameSport.Length < MinimumHistoryCount)
        {
            return 0;
        }

        int risk = 0;

        double averageHistoricalDistance =
            sameSport.Average(item =>
                item.DistanceKilometers);

        if (averageHistoricalDistance > 0 &&
            distanceKilometers >= 5 &&
            distanceKilometers >
                averageHistoricalDistance * 3d)
        {
            risk += 25;
            reasons.Add("DistanceAboveThreeTimesHistoricalAverage");
        }

        double averageHistoricalSpeedKmh =
            sameSport.Average(item =>
                item.DistanceKilometers /
                (item.MovingTimeSeconds / 3600d));

        if (averageHistoricalSpeedKmh > 0 &&
            distanceKilometers >= 3 &&
            averageSpeedKmh >
                averageHistoricalSpeedKmh * 1.75d)
        {
            risk += 25;
            reasons.Add("SpeedFarAboveHistoricalAverage");
        }

        return risk;
    }

    private static double GetAverageSpeedKmh(
        StravaActivityResult activity)
    {
        if (activity.AverageSpeedMetersPerSecond is > 0)
        {
            return activity.AverageSpeedMetersPerSecond.Value * 3.6d;
        }

        if (activity.MovingTimeSeconds <= 0)
        {
            return 0d;
        }

        return
            (activity.DistanceMeters / 1000d) /
            (activity.MovingTimeSeconds / 3600d);
    }

    private static bool RequiresDistance(
        AppKmActivityType activityType)
    {
        return activityType != AppKmActivityType.Gym;
    }
}
