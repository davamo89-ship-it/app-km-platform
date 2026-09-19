using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using AppKm.Identity.Application.Interfaces;
using AppKm.Identity.Domain.Aggregates.Roles;
using AppKm.Identity.Domain.Aggregates.Users;
using AppKm.Identity.Infrastructure.DependencyInjection;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace AppKm.Identity.Application.Tests.Security;

public sealed class IdentitySecurityServicesTests
{
    [Fact]
    public void PasswordHasher_HashCanBeVerified()
    {
        using ServiceProvider provider = CreateProvider();
        var hasher = provider.GetRequiredService<IPasswordHasher>();

        string hash = hasher.Hash("Password1");

        Assert.NotEqual("Password1", hash);
        Assert.True(hasher.Verify(hash, "Password1"));
        Assert.False(hasher.Verify(hash, "WrongPassword1"));
    }

    [Fact]
    public void RefreshTokenGenerator_GeneratesRandomTokenAndStableHash()
    {
        using ServiceProvider provider = CreateProvider();
        var generator =
            provider.GetRequiredService<IRefreshTokenGenerator>();

        RefreshTokenResult first = generator.Generate();
        RefreshTokenResult second = generator.Generate();

        Assert.NotEqual(first.Token, second.Token);
        Assert.Equal(first.TokenHash, generator.Hash(first.Token));
        Assert.Equal(64, first.TokenHash.Length);
    }

    [Fact]
    public void JwtGenerator_IncludesSubjectEmailRoleAndExpiration()
    {
        using ServiceProvider provider = CreateProvider();
        var generator =
            provider.GetRequiredService<IJwtTokenGenerator>();

        UserId userId = UserId.New();

        JwtTokenResult result =
            generator.Generate(
                userId,
                "user@example.com",
                [RoleNames.Athlete]);

        var handler = new JwtSecurityTokenHandler();
        JwtSecurityToken token =
            handler.ReadJwtToken(result.AccessToken);

        Assert.Equal("AppKm.Tests", token.Issuer);
        Assert.Contains("AppKm.Mobile", token.Audiences);
        Assert.Contains(
            token.Claims,
            claim =>
                claim.Type == JwtRegisteredClaimNames.Sub &&
                claim.Value == userId.Value.ToString());
        Assert.Contains(
            token.Claims,
            claim =>
                claim.Type == JwtRegisteredClaimNames.Email &&
                claim.Value == "user@example.com");
        Assert.Contains(
            token.Claims,
            claim =>
                claim.Type == "role" &&
                claim.Value == RoleNames.Athlete);
        Assert.True(result.ExpiresAtUtc > DateTimeOffset.UtcNow);
    }

    private static ServiceProvider CreateProvider()
    {
        Dictionary<string, string?> values = new()
        {
            ["ConnectionStrings:IdentityDatabase"] =
                "Host=localhost;Port=5433;Database=appkm;Username=appkm;Password=appkm",
            ["Jwt:Issuer"] = "AppKm.Tests",
            ["Jwt:Audience"] = "AppKm.Mobile",
            ["Jwt:Secret"] =
                "TEST_ONLY_SECRET_123456789012345678901234567890",
            ["Jwt:ExpirationMinutes"] = "15",
            ["RefreshToken:SizeInBytes"] = "64",
            ["RefreshToken:ExpirationDays"] = "30"
        };

        IConfiguration configuration =
            new ConfigurationBuilder()
                .AddInMemoryCollection(values)
                .Build();

        var services = new ServiceCollection();

        services.AddIdentityInfrastructure(configuration);

        return services.BuildServiceProvider();
    }
}
