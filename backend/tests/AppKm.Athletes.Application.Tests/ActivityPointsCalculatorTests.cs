using Xunit;
using AppKm.Athletes.Application.Activities;
using AppKm.Athletes.Domain.Activities;

namespace AppKm.Athletes.Application.Tests.Activities;

public sealed class ActivityPointsCalculatorTests
{
    private readonly ActivityPointsCalculator _calculator = new();

    [Theory]
    [InlineData(0.0, 0)]
    [InlineData(1.49, 1)]
    [InlineData(1.50, 2)]
    [InlineData(10.49, 10)]
    [InlineData(10.50, 11)]
    public void Calculate_RoundsHalfUp(
        double distanceKilometers,
        int expectedPoints)
    {
        int result =
            _calculator.Calculate(
                AppKmActivityType.Running,
                distanceKilometers);

        Assert.Equal(expectedPoints, result);
    }

    [Fact]
    public void Calculate_NegativeDistance_Throws()
    {
        Assert.Throws<ArgumentOutOfRangeException>(
            () => _calculator.Calculate(
                AppKmActivityType.Cycling,
                -0.01));
    }
}
