using Xunit;
using AppKm.Athletes.Application.Activities;
using AppKm.Athletes.Application.Interfaces;

namespace AppKm.Athletes.Application.Tests.Activities;

public sealed class StravaActivityValidatorTests
{
    private readonly StravaActivityValidator _validator = new();

    [Fact]
    public void Validate_ValidRunningActivity_ReturnsValid()
    {
        DateTimeOffset now =
            new(2026, 9, 18, 18, 0, 0, TimeSpan.FromHours(-6));

        StravaActivityResult activity =
            CreateActivity(
                "Run",
                5_000,
                new DateTime(2026, 9, 18, 7, 30, 0));

        ActivityValidationResult result =
            _validator.Validate(activity, now);

        Assert.True(result.IsValid);
        Assert.Null(result.Reason);
    }

    [Fact]
    public void Validate_UnsupportedSport_ReturnsExpectedReason()
    {
        DateTimeOffset now =
            new(2026, 9, 18, 18, 0, 0, TimeSpan.FromHours(-6));

        StravaActivityResult activity =
            CreateActivity(
                "Kayaking",
                5_000,
                new DateTime(2026, 9, 18, 7, 30, 0));

        ActivityValidationResult result =
            _validator.Validate(activity, now);

        Assert.False(result.IsValid);
        Assert.Equal("UnsupportedSportType", result.Reason);
    }

    [Fact]
    public void Validate_PreviousDay_ReturnsExpectedReason()
    {
        DateTimeOffset now =
            new(2026, 9, 18, 18, 0, 0, TimeSpan.FromHours(-6));

        StravaActivityResult activity =
            CreateActivity(
                "Run",
                5_000,
                new DateTime(2026, 9, 17, 23, 30, 0));

        ActivityValidationResult result =
            _validator.Validate(activity, now);

        Assert.False(result.IsValid);
        Assert.Equal("ActivityNotFromCurrentDay", result.Reason);
    }

    [Fact]
    public void Validate_CyclingAboveLimit_ReturnsExpectedReason()
    {
        DateTimeOffset now =
            new(2026, 9, 18, 18, 0, 0, TimeSpan.FromHours(-6));

        StravaActivityResult activity =
            CreateActivity(
                "Ride",
                185_001,
                new DateTime(2026, 9, 18, 7, 30, 0));

        ActivityValidationResult result =
            _validator.Validate(activity, now);

        Assert.False(result.IsValid);
        Assert.Equal("CyclingDistanceLimitExceeded", result.Reason);
    }

    [Fact]
    public void Validate_RunningAboveLimit_ReturnsExpectedReason()
    {
        DateTimeOffset now =
            new(2026, 9, 18, 18, 0, 0, TimeSpan.FromHours(-6));

        StravaActivityResult activity =
            CreateActivity(
                "Run",
                43_001,
                new DateTime(2026, 9, 18, 7, 30, 0));

        ActivityValidationResult result =
            _validator.Validate(activity, now);

        Assert.False(result.IsValid);
        Assert.Equal("RunningDistanceLimitExceeded", result.Reason);
    }

    private static StravaActivityResult CreateActivity(
        string sportType,
        double distanceMeters,
        DateTime startDateLocal)
    {
        return new StravaActivityResult(
            123456789L,
            "Test activity",
            sportType,
            distanceMeters,
            new DateTimeOffset(
                startDateLocal,
                TimeSpan.FromHours(-6)),
            startDateLocal,
            3_600,
            3_000);
    }
}
