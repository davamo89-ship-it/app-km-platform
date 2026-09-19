using System.Reflection;
using AppKm.Identity.Application.Commands.LoginUser;
using AppKm.Identity.Application.Commands.RefreshSession;
using AppKm.Identity.Application.Interfaces;
using AppKm.Identity.Domain.Aggregates.Sessions;
using AppKm.Identity.Domain.Aggregates.Users;
using AppKm.Identity.Domain.ValueObjects;
using Xunit;

namespace AppKm.Identity.Application.Tests.Commands;

public sealed class LoginAndRefreshSessionTests
{
    [Fact]
    public async Task Login_UnknownUser_ReturnsInvalidCredentials()
    {
        var users = new FakeUserRepository();
        var handler = CreateLoginHandler(users);

        var result = await handler.HandleAsync(
            new LoginUserCommand("missing@example.com", "Password1"),
            CancellationToken.None);

        Assert.True(result.IsFailure);
        Assert.Equal(LoginUserErrors.InvalidCredentials, result.Error);
    }

    [Fact]
    public async Task Login_WrongPassword_ReturnsInvalidCredentials()
    {
        var users = new FakeUserRepository
        {
            UserByEmail = CreateUser(active: true)
        };

        var handler = CreateLoginHandler(users);

        var result = await handler.HandleAsync(
            new LoginUserCommand("user@example.com", "WrongPassword1"),
            CancellationToken.None);

        Assert.True(result.IsFailure);
        Assert.Equal(LoginUserErrors.InvalidCredentials, result.Error);
    }

    [Fact]
    public async Task Login_InactiveUser_ReturnsAccountNotActive()
    {
        var users = new FakeUserRepository
        {
            UserByEmail = CreateUser(active: false)
        };

        var handler = CreateLoginHandler(users);

        var result = await handler.HandleAsync(
            new LoginUserCommand("user@example.com", "Password1"),
            CancellationToken.None);

        Assert.True(result.IsFailure);
        Assert.Equal(LoginUserErrors.AccountNotActive, result.Error);
    }

    [Fact]
    public async Task Login_ValidCredentials_CreatesSessionAndTokens()
    {
        var users = new FakeUserRepository
        {
            UserByEmail = CreateUser(active: true)
        };

        var sessions = new FakeSessionRepository();
        var unitOfWork = new FakeUnitOfWork();

        var handler = CreateLoginHandler(
            users,
            sessions,
            unitOfWork);

        var result = await handler.HandleAsync(
            new LoginUserCommand("user@example.com", "Password1"),
            CancellationToken.None);

        Assert.True(result.IsSuccess);
        Assert.Equal("access-token", result.Value.AccessToken);
        Assert.Equal("refresh-token", result.Value.RefreshToken);
        Assert.Single(sessions.Added);
        Assert.Equal("refresh-hash", sessions.Added[0].RefreshTokenHash);
        Assert.Equal(1, unitOfWork.SaveCalls);
    }

    [Fact]
    public async Task Refresh_RevokedSession_ReturnsInactiveSession()
    {
        var session = CreateSession();
        session.Revoke(new DateTimeOffset(2026, 9, 19, 11, 0, 0, TimeSpan.Zero));

        var sessions = new FakeSessionRepository { Session = session };
        var users = new FakeUserRepository { UserById = CreateUser(active: true) };
        var handler = CreateRefreshHandler(sessions, users);

        var result = await handler.HandleAsync(
            new RefreshSessionCommand("refresh-token"),
            CancellationToken.None);

        Assert.True(result.IsFailure);
        Assert.Equal(RefreshSessionErrors.InactiveSession, result.Error);
    }

    [Fact]
    public async Task Refresh_ValidSession_RotatesRefreshToken()
    {
        var session = CreateSession();
        var sessions = new FakeSessionRepository { Session = session };
        var users = new FakeUserRepository { UserById = CreateUser(active: true) };
        var unitOfWork = new FakeUnitOfWork();

        var handler = CreateRefreshHandler(
            sessions,
            users,
            unitOfWork);

        var result = await handler.HandleAsync(
            new RefreshSessionCommand("refresh-token"),
            CancellationToken.None);

        Assert.True(result.IsSuccess);
        Assert.Equal("access-token", result.Value.AccessToken);
        Assert.Equal("refresh-token", result.Value.RefreshToken);
        Assert.Equal("refresh-hash", session.RefreshTokenHash);
        Assert.Equal(1, unitOfWork.SaveCalls);
    }

    private static LoginUserCommandHandler CreateLoginHandler(
        FakeUserRepository users,
        FakeSessionRepository? sessions = null,
        FakeUnitOfWork? unitOfWork = null)
    {
        return new LoginUserCommandHandler(
            users,
            new FakeUserRoleRepository(),
            sessions ?? new FakeSessionRepository(),
            new FakePasswordHasher(),
            new FakeJwtTokenGenerator(),
            new FakeRefreshTokenGenerator(),
            unitOfWork ?? new FakeUnitOfWork(),
            new FakeClock());
    }

    private static RefreshSessionCommandHandler CreateRefreshHandler(
        FakeSessionRepository sessions,
        FakeUserRepository users,
        FakeUnitOfWork? unitOfWork = null)
    {
        return new RefreshSessionCommandHandler(
            sessions,
            users,
            new FakeUserRoleRepository(),
            new FakeRefreshTokenGenerator(),
            new FakeJwtTokenGenerator(),
            unitOfWork ?? new FakeUnitOfWork(),
            new FakeClock());
    }

    private static User CreateUser(bool active)
    {
        var email = Email.Create("user@example.com").Value;
        var hash = PasswordHash.Create("hashed::Password1").Value;

        User user = User.Register(
            UserId.New(),
            email,
            hash,
            new DateTimeOffset(2026, 9, 1, 0, 0, 0, TimeSpan.Zero)).Value;

        if (active)
        {
            PropertyInfo statusProperty =
                typeof(User).GetProperty(
                    nameof(User.Status),
                    BindingFlags.Instance | BindingFlags.Public)
                ?? throw new InvalidOperationException(
                    "User.Status property was not found.");

            statusProperty.SetValue(
                user,
                UserStatus.Active);
        }

        return user;
    }

    private static Session CreateSession()
    {
        return Session.Create(
            SessionId.New(),
            UserId.New(),
            "current-hash",
            new DateTimeOffset(2026, 9, 1, 0, 0, 0, TimeSpan.Zero),
            new DateTimeOffset(2026, 10, 19, 0, 0, 0, TimeSpan.Zero)).Value;
    }
}

internal sealed class FakeSessionRepository : ISessionRepository
{
    public Session? Session { get; set; }
    public List<Session> Added { get; } = [];

    public Task<Session?> GetByRefreshTokenHashAsync(
        string refreshTokenHash,
        CancellationToken cancellationToken) =>
        Task.FromResult(Session);

    public Task<IReadOnlyCollection<Session>> GetActiveByUserIdAsync(
        UserId userId,
        DateTimeOffset utcNow,
        CancellationToken cancellationToken) =>
        Task.FromResult<IReadOnlyCollection<Session>>([]);

    public Task AddAsync(
        Session session,
        CancellationToken cancellationToken)
    {
        Added.Add(session);
        return Task.CompletedTask;
    }
}

internal sealed class FakeJwtTokenGenerator : IJwtTokenGenerator
{
    public JwtTokenResult Generate(
        UserId userId,
        string email,
        IReadOnlyCollection<string> roles) =>
        new(
            "access-token",
            new DateTimeOffset(2026, 9, 19, 12, 15, 0, TimeSpan.Zero));
}

internal sealed class FakeRefreshTokenGenerator : IRefreshTokenGenerator
{
    public RefreshTokenResult Generate() =>
        new("refresh-token", "refresh-hash");

    public string Hash(string refreshToken) =>
        "current-hash";
}
