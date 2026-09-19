using AppKm.Identity.Application.Commands.RegisterUser;
using AppKm.Identity.Application.Interfaces;
using AppKm.Identity.Domain.Aggregates.Roles;
using AppKm.Identity.Domain.Aggregates.Users;
using AppKm.Identity.Domain.ValueObjects;
using Platform.SharedKernel.Abstractions;
using Xunit;

namespace AppKm.Identity.Application.Tests.Commands;

public sealed class RegisterUserCommandHandlerTests
{
    [Theory]
    [InlineData("", "Identity.Register.PasswordRequired")]
    [InlineData("Abc1", "Identity.Register.PasswordTooShort")]
    [InlineData("abcdefgh1", "Identity.Register.PasswordRequiresUppercase")]
    [InlineData("ABCDEFGH1", "Identity.Register.PasswordRequiresLowercase")]
    [InlineData("Abcdefgh", "Identity.Register.PasswordRequiresDigit")]
    public async Task Handle_InvalidPassword_ReturnsExpectedError(
        string password,
        string expectedCode)
    {
        var context = new TestContext();
        var handler = context.CreateHandler();

        var result = await handler.HandleAsync(
            new RegisterUserCommand("user@example.com", password),
            CancellationToken.None);

        Assert.True(result.IsFailure);
        Assert.Equal(expectedCode, result.Error.Code);
        Assert.Empty(context.UserRepository.Added);
        Assert.Equal(0, context.UnitOfWork.SaveCalls);
    }

    [Fact]
    public async Task Handle_DuplicateEmail_ReturnsExpectedError()
    {
        var context = new TestContext();
        context.UserRepository.EmailExists = true;
        var handler = context.CreateHandler();

        var result = await handler.HandleAsync(
            new RegisterUserCommand("user@example.com", "Password1"),
            CancellationToken.None);

        Assert.True(result.IsFailure);
        Assert.Equal(RegisterUserErrors.EmailAlreadyExists, result.Error);
        Assert.Empty(context.UserRepository.Added);
    }

    [Fact]
    public async Task Handle_ValidRegistration_CreatesAthleteUserAndProfile()
    {
        var context = new TestContext();
        var handler = context.CreateHandler();

        var result = await handler.HandleAsync(
            new RegisterUserCommand("NewUser@example.com", "Password1"),
            CancellationToken.None);

        Assert.True(result.IsSuccess);
        Assert.Single(context.UserRepository.Added);
        Assert.Single(context.UserRoleRepository.Added);
        Assert.Equal(RoleIds.Athlete, context.UserRoleRepository.Added[0].RoleId);
        Assert.Equal(1, context.UnitOfWork.SaveCalls);
        Assert.Equal(result.Value.Value, context.Provisioner.LastUserId);
        Assert.Equal("NewUser", context.Provisioner.LastDisplayName);
    }

    private sealed class TestContext
    {
        public FakeUserRepository UserRepository { get; } = new();
        public FakeUserRoleRepository UserRoleRepository { get; } = new();
        public FakePasswordHasher PasswordHasher { get; } = new();
        public FakeUnitOfWork UnitOfWork { get; } = new();
        public FakeClock Clock { get; } = new();
        public FakeAthleteProfileProvisioner Provisioner { get; } = new();

        public RegisterUserCommandHandler CreateHandler() =>
            new(
                UserRepository,
                UserRoleRepository,
                PasswordHasher,
                UnitOfWork,
                Clock,
                Provisioner);
    }
}

internal sealed class FakeClock : IClock
{
    public DateTimeOffset UtcNow { get; set; } =
        new(2026, 9, 19, 12, 0, 0, TimeSpan.Zero);
}

internal sealed class FakePasswordHasher : IPasswordHasher
{
    public string Hash(string password) => $"hashed::{password}";

    public bool Verify(string passwordHash, string providedPassword) =>
        passwordHash == $"hashed::{providedPassword}";
}

internal sealed class FakeUserRepository : IUserRepository
{
    public bool EmailExists { get; set; }
    public User? UserByEmail { get; set; }
    public User? UserById { get; set; }
    public List<User> Added { get; } = [];

    public Task<User?> GetByIdAsync(
        UserId userId,
        CancellationToken cancellationToken) =>
        Task.FromResult(UserById);

    public Task<User?> GetByEmailAsync(
        Email email,
        CancellationToken cancellationToken) =>
        Task.FromResult(UserByEmail);

    public Task<bool> ExistsByEmailAsync(
        Email email,
        CancellationToken cancellationToken) =>
        Task.FromResult(EmailExists);

    public Task AddAsync(
        User user,
        CancellationToken cancellationToken)
    {
        Added.Add(user);
        return Task.CompletedTask;
    }
}

internal sealed class FakeUserRoleRepository : IUserRoleRepository
{
    public List<UserRole> Added { get; } = [];
    public IReadOnlyCollection<string> Roles { get; set; } = [RoleNames.Athlete];

    public Task AddAsync(
        UserRole userRole,
        CancellationToken cancellationToken)
    {
        Added.Add(userRole);
        return Task.CompletedTask;
    }

    public Task<bool> ExistsAsync(
        UserId userId,
        RoleId roleId,
        CancellationToken cancellationToken) =>
        Task.FromResult(false);

    public Task<IReadOnlyCollection<string>> GetRoleNamesByUserIdAsync(
        UserId userId,
        CancellationToken cancellationToken) =>
        Task.FromResult(Roles);

    public Task<IReadOnlyCollection<Guid>> GetUserIdsByRoleNameAsync(
        string roleName,
        CancellationToken cancellationToken) =>
        Task.FromResult<IReadOnlyCollection<Guid>>([]);
}

internal sealed class FakeUnitOfWork : IUnitOfWork
{
    public int SaveCalls { get; private set; }

    public Task<int> SaveChangesAsync(
        CancellationToken cancellationToken = default)
    {
        SaveCalls++;
        return Task.FromResult(1);
    }
}

internal sealed class FakeAthleteProfileProvisioner : IAthleteProfileProvisioner
{
    public Guid? LastUserId { get; private set; }
    public string? LastDisplayName { get; private set; }

    public Task CreateAsync(
        Guid userId,
        string displayName,
        CancellationToken cancellationToken)
    {
        LastUserId = userId;
        LastDisplayName = displayName;
        return Task.CompletedTask;
    }
}
