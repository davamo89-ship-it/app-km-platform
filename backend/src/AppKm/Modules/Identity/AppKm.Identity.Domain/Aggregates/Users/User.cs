using AppKm.Identity.Domain.Aggregates.Users.Events;
using AppKm.Identity.Domain.ValueObjects;
using Platform.SharedKernel.Entities;
using Platform.SharedKernel.Results;

namespace AppKm.Identity.Domain.Aggregates.Users;

public sealed class User : AggregateRoot<UserId>
{
    // Utilizado únicamente por Entity Framework Core.
    private User()
        : base(default)
    {
        Email = null!;
        PasswordHash = null!;
        Status = null!;
    }

    // Constructor utilizado internamente por el dominio.
    private User(
        UserId id,
        Email email,
        PasswordHash passwordHash,
        UserStatus status,
        DateTimeOffset createdAtUtc)
        : base(id)
    {
        Email = email;
        PasswordHash = passwordHash;
        Status = status;
        CreatedAtUtc = createdAtUtc;
    }

    public Email Email { get; private set; }

    public PasswordHash PasswordHash { get; private set; }

    public UserStatus Status { get; private set; }

    public DateTimeOffset CreatedAtUtc { get; private set; }

    public string? PasswordResetCodeHash { get; private set; }

    public DateTimeOffset? PasswordResetRequestedAtUtc { get; private set; }

    public DateTimeOffset? PasswordResetExpiresAtUtc { get; private set; }

    public static Result<User> Register(
        UserId id,
        Email email,
        PasswordHash passwordHash,
        DateTimeOffset occurredOnUtc)
    {
        ArgumentNullException.ThrowIfNull(email);
        ArgumentNullException.ThrowIfNull(passwordHash);

        if (id.Value == Guid.Empty)
        {
            throw new ArgumentException(
                "The user identifier cannot be empty.",
                nameof(id));
        }

        var user = new User(
            id,
            email,
            passwordHash,
            UserStatus.PendingVerification,
            occurredOnUtc);

        user.RaiseDomainEvent(
            new UserRegisteredDomainEvent(
                Guid.NewGuid(),
                user.Id,
                user.Email,
                occurredOnUtc));

        return Result<User>.Success(user);
    }

    public void Activate()
    {
        if (Status == UserStatus.PendingVerification)
        {
            Status = UserStatus.Active;
        }
    }

    public void BeginPasswordReset(
        string codeHash,
        DateTimeOffset requestedAtUtc,
        DateTimeOffset expiresAtUtc)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(codeHash);

        if (expiresAtUtc <= requestedAtUtc)
        {
            throw new ArgumentException(
                "Password reset expiration must be after the request time.",
                nameof(expiresAtUtc));
        }

        PasswordResetCodeHash = codeHash.Trim();
        PasswordResetRequestedAtUtc = requestedAtUtc;
        PasswordResetExpiresAtUtc = expiresAtUtc;
    }

    public bool HasUsablePasswordReset(DateTimeOffset utcNow)
    {
        return
            !string.IsNullOrWhiteSpace(PasswordResetCodeHash) &&
            PasswordResetExpiresAtUtc.HasValue &&
            PasswordResetExpiresAtUtc.Value > utcNow;
    }

    public void CompletePasswordReset(
        PasswordHash newPasswordHash)
    {
        ArgumentNullException.ThrowIfNull(newPasswordHash);

        PasswordHash = newPasswordHash;
        PasswordResetCodeHash = null;
        PasswordResetRequestedAtUtc = null;
        PasswordResetExpiresAtUtc = null;
    }

    public void ClearPasswordReset()
    {
        PasswordResetCodeHash = null;
        PasswordResetRequestedAtUtc = null;
        PasswordResetExpiresAtUtc = null;
    }
}
