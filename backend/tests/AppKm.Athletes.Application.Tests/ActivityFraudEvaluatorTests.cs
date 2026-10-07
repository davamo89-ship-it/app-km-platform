using AppKm.Athletes.Application.Activities;
using AppKm.Athletes.Application.Interfaces;
using AppKm.Athletes.Domain.Activities;
using AppKm.Athletes.Domain.Aggregates.AthleteActivities;
using AppKm.Athletes.Domain.Aggregates.Athletes;
using Xunit;

namespace AppKm.Athletes.Application.Tests.Activities;

public sealed class ActivityFraudEvaluatorTests
{
    private readonly ActivityFraudEvaluator _evaluator = new();

    [Fact]
    public void ManualActivity_WithoutObjectiveEvidence_IsIneligible()
    {
        StravaActivityResult activity =
            CreateActivity(
                "Ride",
                20,
                25,
                manual: true);

        ActivityFraudAssessment result =
            _evaluator.Evaluate(
                activity,
                AppKmActivityType.Cycling,
                []);

        Assert.Equal(
            ActivityFraudStatus.Ineligible,
            result.Status);

        Assert.Contains(
            "ManualActivityInsufficientEvidence",
            result.Reasons);
    }

    [Fact]
    public void ManualActivity_WithStrongTelemetry_CanRemainEligible()
    {
        StravaActivityResult activity =
            CreateActivity(
                "Ride",
                20,
                30,
                manual: true,
                deviceName: "Recorded device",
                hasHeartRate: true,
                deviceWatts: true,
                averageWatts: 220,
                averageCadence: 82,
                elevationGainMeters: 180,
                uploadId: 999);

        ActivityFraudAssessment result =
            _evaluator.Evaluate(
                activity,
                AppKmActivityType.Cycling,
                []);

        Assert.Equal(
            ActivityFraudStatus.Valid,
            result.Status);
    }

    [Fact]
    public void StravaFlaggedActivity_GoesToReview()
    {
        StravaActivityResult activity =
            CreateActivity(
                "Run",
                10,
                12,
                flagged: true);

        ActivityFraudAssessment result =
            _evaluator.Evaluate(
                activity,
                AppKmActivityType.Running,
                []);

        Assert.Equal(
            ActivityFraudStatus.Review,
            result.Status);

        Assert.Contains(
            "FlaggedByStrava",
            result.Reasons);
    }

    [Fact]
    public void WalkingAtCarSpeed_IsInvalid()
    {
        StravaActivityResult activity =
            CreateActivity(
                "Walk",
                30,
                72);

        ActivityFraudAssessment result =
            _evaluator.Evaluate(
                activity,
                AppKmActivityType.Walking,
                []);

        Assert.Equal(
            ActivityFraudStatus.Invalid,
            result.Status);
    }

    [Fact]
    public void RunningAtImpossibleAverageSpeed_IsInvalid()
    {
        StravaActivityResult activity =
            CreateActivity(
                "Run",
                10,
                40);

        ActivityFraudAssessment result =
            _evaluator.Evaluate(
                activity,
                AppKmActivityType.Running,
                []);

        Assert.Equal(
            ActivityFraudStatus.Invalid,
            result.Status);
    }

    [Fact]
    public void EliteRunningPerformance_IsNotAutomaticallyInvalid()
    {
        StravaActivityResult activity =
            CreateActivity(
                "Run",
                10,
                23.5,
                deviceName: "GPS watch",
                hasHeartRate: true,
                elevationGainMeters: 20,
                uploadId: 123);

        ActivityFraudAssessment result =
            _evaluator.Evaluate(
                activity,
                AppKmActivityType.Running,
                []);

        Assert.NotEqual(
            ActivityFraudStatus.Invalid,
            result.Status);
    }

    [Fact]
    public void Cycling50KmhFlat_WithStrongTelemetry_IsValid()
    {
        StravaActivityResult activity =
            CreateActivity(
                "Ride",
                25,
                50,
                deviceName: "Bike computer",
                hasHeartRate: true,
                deviceWatts: true,
                averageWatts: 350,
                averageCadence: 92,
                elevationGainMeters: 50,
                elevationHighMeters: 130,
                elevationLowMeters: 80,
                uploadId: 555);

        ActivityFraudAssessment result =
            _evaluator.Evaluate(
                activity,
                AppKmActivityType.Cycling,
                []);

        Assert.Equal(
            ActivityFraudStatus.Valid,
            result.Status);
    }

    [Fact]
    public void Cycling65Kmh_WithLargeElevationRange_IsNotAutomaticallyInvalid()
    {
        StravaActivityResult activity =
            CreateActivity(
                "Ride",
                40,
                65,
                deviceName: "Bike computer",
                hasHeartRate: true,
                averageCadence: 75,
                elevationGainMeters: 120,
                elevationHighMeters: 3400,
                elevationLowMeters: 600,
                uploadId: 777);

        ActivityFraudAssessment result =
            _evaluator.Evaluate(
                activity,
                AppKmActivityType.Cycling,
                []);

        Assert.NotEqual(
            ActivityFraudStatus.Invalid,
            result.Status);
    }

    [Fact]
    public void Cycling65KmhFlat_WithWeakEvidence_GoesToReview()
    {
        StravaActivityResult activity =
            CreateActivity(
                "Ride",
                40,
                65,
                elevationGainMeters: 50,
                elevationHighMeters: 150,
                elevationLowMeters: 100);

        ActivityFraudAssessment result =
            _evaluator.Evaluate(
                activity,
                AppKmActivityType.Cycling,
                []);

        Assert.Equal(
            ActivityFraudStatus.Review,
            result.Status);
    }

    [Fact]
    public void CyclingAtClearlyImpossibleAverageSpeed_IsInvalid()
    {
        StravaActivityResult activity =
            CreateActivity(
                "Ride",
                30,
                120);

        ActivityFraudAssessment result =
            _evaluator.Evaluate(
                activity,
                AppKmActivityType.Cycling,
                []);

        Assert.Equal(
            ActivityFraudStatus.Invalid,
            result.Status);
    }

    [Fact]
    public void SwimmingAtClearlyImpossibleAverageSpeed_IsInvalid()
    {
        StravaActivityResult activity =
            CreateActivity(
                "Swim",
                2,
                12);

        ActivityFraudAssessment result =
            _evaluator.Evaluate(
                activity,
                AppKmActivityType.Swimming,
                []);

        Assert.Equal(
            ActivityFraudStatus.Invalid,
            result.Status);
    }

    [Fact]
    public void NormalSwimmingActivity_IsValid()
    {
        StravaActivityResult activity =
            CreateActivity(
                "Swim",
                2,
                3.5,
                deviceName: "Swim watch",
                hasHeartRate: true,
                uploadId: 888);

        ActivityFraudAssessment result =
            _evaluator.Evaluate(
                activity,
                AppKmActivityType.Swimming,
                []);

        Assert.Equal(
            ActivityFraudStatus.Valid,
            result.Status);
    }

    [Fact]
    public void LongGymSession_IsInvalid()
    {
        StravaActivityResult activity =
            CreateGymActivity(
                elapsedSeconds: 9 * 60 * 60);

        ActivityFraudAssessment result =
            _evaluator.Evaluate(
                activity,
                AppKmActivityType.Gym,
                []);

        Assert.Equal(
            ActivityFraudStatus.Invalid,
            result.Status);
    }

    [Fact]
    public void VeryShortGymSession_GoesToReview()
    {
        StravaActivityResult activity =
            CreateGymActivity(
                elapsedSeconds: 2 * 60);

        ActivityFraudAssessment result =
            _evaluator.Evaluate(
                activity,
                AppKmActivityType.Gym,
                []);

        Assert.Equal(
            ActivityFraudStatus.Review,
            result.Status);
    }

    [Fact]
    public void ThreeTimesHistoricalDistance_AddsRisk()
    {
        IReadOnlyList<AthleteActivity> history =
            CreateHistory(
                AppKmActivityType.Running,
                distanceKilometers: 5,
                speedKmh: 10,
                count: 5);

        StravaActivityResult activity =
            CreateActivity(
                "Run",
                20,
                10,
                deviceName: "GPS watch",
                hasHeartRate: true,
                uploadId: 999);

        ActivityFraudAssessment result =
            _evaluator.Evaluate(
                activity,
                AppKmActivityType.Running,
                history);

        Assert.Contains(
            "DistanceAboveThreeTimesHistoricalAverage",
            result.Reasons);
    }

    [Fact]
    public void HistoryWithFewerThanFiveActivities_DoesNotTriggerBaselineRule()
    {
        IReadOnlyList<AthleteActivity> history =
            CreateHistory(
                AppKmActivityType.Running,
                distanceKilometers: 5,
                speedKmh: 10,
                count: 4);

        StravaActivityResult activity =
            CreateActivity(
                "Run",
                20,
                10);

        ActivityFraudAssessment result =
            _evaluator.Evaluate(
                activity,
                AppKmActivityType.Running,
                history);

        Assert.DoesNotContain(
            "DistanceAboveThreeTimesHistoricalAverage",
            result.Reasons);
    }

    private static StravaActivityResult CreateActivity(
        string sportType,
        double distanceKilometers,
        double averageSpeedKmh,
        bool manual = false,
        bool flagged = false,
        string? deviceName = null,
        bool hasHeartRate = false,
        bool deviceWatts = false,
        double? averageWatts = null,
        double? averageCadence = null,
        double? elevationGainMeters = null,
        double? elevationHighMeters = null,
        double? elevationLowMeters = null,
        long? uploadId = null)
    {
        double meters =
            distanceKilometers * 1000d;

        int movingSeconds =
            averageSpeedKmh <= 0
                ? 0
                : (int)Math.Round(
                    distanceKilometers /
                    averageSpeedKmh *
                    3600d);

        return new StravaActivityResult(
            123456789L,
            "Test activity",
            sportType,
            meters,
            DateTimeOffset.UtcNow,
            DateTime.Now,
            movingSeconds,
            movingSeconds,
            manual,
            flagged,
            averageSpeedKmh / 3.6d,
            averageSpeedKmh / 3.6d * 1.15d,
            elevationGainMeters,
            elevationHighMeters,
            elevationLowMeters,
            hasHeartRate,
            deviceWatts,
            averageWatts,
            hasHeartRate ? 150 : null,
            averageCadence,
            deviceName,
            false,
            uploadId,
            uploadId.HasValue
                ? $"upload-{uploadId.Value}"
                : null);
    }

    private static StravaActivityResult CreateGymActivity(
        int elapsedSeconds)
    {
        return new StravaActivityResult(
            987654321L,
            "Gym",
            "WeightTraining",
            0,
            DateTimeOffset.UtcNow,
            DateTime.Now,
            elapsedSeconds,
            elapsedSeconds,
            false,
            false,
            0,
            0,
            null,
            null,
            null,
            true,
            false,
            null,
            120,
            null,
            "Watch",
            false,
            123,
            "gym-123");
    }

    private static IReadOnlyList<AthleteActivity> CreateHistory(
        AppKmActivityType activityType,
        double distanceKilometers,
        double speedKmh,
        int count)
    {
        var result =
            new List<AthleteActivity>();

        AthleteId athleteId =
            AthleteId.New();

        int movingTimeSeconds =
            (int)Math.Round(
                distanceKilometers /
                speedKmh *
                3600d);

        for (int i = 0; i < count; i++)
        {
            result.Add(
                AthleteActivity.Create(
                    athleteId,
                    1000 + i,
                    activityType,
                    distanceKilometers,
                    (int)Math.Round(distanceKilometers),
                    DateTimeOffset.UtcNow.AddDays(-(i + 1)),
                    DateTime.Now.AddDays(-(i + 1)),
                    movingTimeSeconds,
                    movingTimeSeconds,
                    DateTimeOffset.UtcNow.AddDays(-(i + 1))));
        }

        return result;
    }
}
