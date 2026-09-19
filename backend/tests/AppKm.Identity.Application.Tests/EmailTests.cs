using AppKm.Identity.Domain.Errors;
using AppKm.Identity.Domain.ValueObjects;
using Xunit;

namespace AppKm.Identity.Application.Tests.Domain;

public sealed class EmailTests
{
    [Fact]
    public void Create_NormalizesEmail()
    {
        var result = Email.Create("  User@Example.COM  ");

        Assert.True(result.IsSuccess);
        Assert.Equal("user@example.com", result.Value.Value);
    }

    [Theory]
    [InlineData(null)]
    [InlineData("")]
    [InlineData("   ")]
    public void Create_EmptyEmail_ReturnsRequired(string? value)
    {
        var result = Email.Create(value);

        Assert.True(result.IsFailure);
        Assert.Equal(EmailErrors.Required, result.Error);
    }

    [Theory]
    [InlineData("not-an-email")]
    [InlineData("@example.com")]
    public void Create_InvalidEmail_ReturnsInvalidFormat(string value)
    {
        var result = Email.Create(value);

        Assert.True(result.IsFailure);
        Assert.Equal(EmailErrors.InvalidFormat, result.Error);
    }

    [Fact]
    public void Create_EmailLongerThan254_ReturnsTooLong()
    {
        string value = new string('a', 245) + "@example.com";

        var result = Email.Create(value);

        Assert.True(result.IsFailure);
        Assert.Equal(EmailErrors.TooLong, result.Error);
    }
}
