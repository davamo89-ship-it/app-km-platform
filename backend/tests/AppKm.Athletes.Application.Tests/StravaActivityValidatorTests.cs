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
    public void Validate_PreviousDayAfterRegistration_ReturnsValid()
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

        Assert.True(result.IsValid);
    }

    [Fact]
    public void Validate_BeforeRegistration_IsRejected()
    {
        var now = new DateTimeOffset(2026, 10, 23, 18, 0, 0, TimeSpan.FromHours(-6));
        var registered = new DateTimeOffset(2026, 10, 13, 10, 0, 0, TimeSpan.FromHours(-6));
        var activity = CreateActivity("Run", 5000, new DateTime(2026, 10, 12, 12, 0, 0));
        var result = _validator.Validate(activity, now, registered);
        Assert.False(result.IsValid);
        Assert.Equal("ActivityBeforeAppKmRegistration", result.Reason);
    }

    [Fact]
    public void Validate_TenDaysAfterRegistration_IsAccepted()
    {
        var now = new DateTimeOffset(2026, 10, 23, 18, 0, 0, TimeSpan.FromHours(-6));
        var registered = new DateTimeOffset(2026, 10, 13, 10, 0, 0, TimeSpan.FromHours(-6));
        var activity = CreateActivity("Run", 5000, new DateTime(2026, 10, 20, 12, 0, 0));
        Assert.True(_validator.Validate(activity, now, registered).IsValid);
    }

    [Fact]
    public void Validate_SameDayBeforeRegistration_IsRejected()
    {
        var now = new DateTimeOffset(2026, 10, 13, 18, 0, 0, TimeSpan.FromHours(-6));
        var registered = new DateTimeOffset(2026, 10, 13, 10, 0, 0, TimeSpan.FromHours(-6));
        var activity = CreateActivity("Run", 5000, new DateTime(2026, 10, 13, 9, 0, 0));
        Assert.Equal("ActivityBeforeAppKmRegistration", _validator.Validate(activity, now, registered).Reason);
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
