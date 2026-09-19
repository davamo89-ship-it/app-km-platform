using AppKm.Identity.Domain.Aggregates.Sessions;
using AppKm.Identity.Domain.Aggregates.Users;
using Xunit;

namespace AppKm.Identity.Application.Tests.Domain;

public sealed class SessionTests
{
    private static readonly DateTimeOffset Now =
        new(2026, 9, 19, 12, 0, 0, TimeSpan.Zero);

    [Fact]
    public void Create_ValidSession_IsActive()
    {
        var result = Session.Create(
            SessionId.New(),
            UserId.New(),
            "hash",
            Now,
            Now.AddDays(30));

        Assert.True(result.IsSuccess);
        Assert.True(result.Value.IsActive(Now));
        Assert.False(result.Value.IsRevoked);
    }

    [Fact]
    public void Create_ExpirationNotAfterCreation_Throws()
    {
        Assert.Throws<ArgumentException>(() =>
            Session.Create(
                SessionId.New(),
                UserId.New(),
                "hash",
                Now,
                Now));
    }

    [Fact]
    public void Revoke_MakesSessionInactive()
    {
        Session session = CreateSession();

        var result = session.Revoke(Now.AddMinutes(1));

        Assert.True(result.IsSuccess);
        Assert.True(session.IsRevoked);
        Assert.False(session.IsActive(Now.AddMinutes(2)));
    }

    [Fact]
    public void RotateRefreshToken_UpdatesHashAndExpiration()
    {
        Session session = CreateSession();
        DateTimeOffset newExpiration = Now.AddDays(45);

        var result =
            session.RotateRefreshToken(
                "new-hash",
                newExpiration,
                Now.AddMinutes(1));

        Assert.True(result.IsSuccess);
        Assert.Equal("new-hash", session.RefreshTokenHash);
        Assert.Equal(newExpiration, session.ExpiresAtUtc);
    }

    [Fact]
    public void RotateRefreshToken_OnRevokedSession_ReturnsInactive()
    {
        Session session = CreateSession();
        session.Revoke(Now);

        var result =
            session.RotateRefreshToken(
                "new-hash",
                Now.AddDays(30),
                Now.AddMinutes(1));

        Assert.True(result.IsFailure);
        Assert.Equal(SessionErrors.Inactive, result.Error);
    }

    private static Session CreateSession()
    {
        return Session.Create(
            SessionId.New(),
            UserId.New(),
            "hash",
            Now,
            Now.AddDays(30)).Value;
    }
}
