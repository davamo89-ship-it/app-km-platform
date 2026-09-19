using Xunit;
using AppKm.Athletes.Application.Activities;
using AppKm.Athletes.Domain.Activities;

namespace AppKm.Athletes.Application.Tests.Activities;

public sealed class StravaSportTypeMapperTests
{
    [Theory]
    [InlineData("Ride", AppKmActivityType.Cycling)]
    [InlineData("MountainBikeRide", AppKmActivityType.Cycling)]
    [InlineData("GravelRide", AppKmActivityType.Cycling)]
    [InlineData("VirtualRide", AppKmActivityType.Cycling)]
    [InlineData("Run", AppKmActivityType.Running)]
    [InlineData("TrailRun", AppKmActivityType.Running)]
    [InlineData("VirtualRun", AppKmActivityType.Running)]
    [InlineData("Walk", AppKmActivityType.Walking)]
    [InlineData("Swim", AppKmActivityType.Swimming)]
    [InlineData("WeightTraining", AppKmActivityType.Gym)]
    [InlineData("Workout", AppKmActivityType.Gym)]
    public void Map_SupportedSport_ReturnsExpectedType(
        string sportType,
        AppKmActivityType expected)
    {
        AppKmActivityType? result =
            StravaSportTypeMapper.Map(sportType);

        Assert.Equal(expected, result);
    }

    [Fact]
    public void Map_UnsupportedSport_ReturnsNull()
    {
        AppKmActivityType? result =
            StravaSportTypeMapper.Map("Kayaking");

        Assert.Null(result);
    }
}
