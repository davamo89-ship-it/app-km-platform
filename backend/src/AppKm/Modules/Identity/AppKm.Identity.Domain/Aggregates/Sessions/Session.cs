using AppKm.Identity.Domain.Aggregates.Users;
using Platform.SharedKernel.Entities;
using Platform.SharedKernel.Results;

namespace AppKm.Identity.Domain.Aggregates.Sessions;

public sealed class Session : AggregateRoot<SessionId>
{
    private Session()
        : base(default)
    {
        RefreshTokenHash = string.Empty;
    }

    private Session(
        SessionId id,
        UserId userId,
        string refreshTokenHash,
        DateTimeOffset createdAtUtc,
        DateTimeOffset expiresAtUtc)
        : base(id)
    {
        UserId = userId;
        RefreshTokenHash = refreshTokenHash;
        CreatedAtUtc = createdAtUtc;
        ExpiresAtUtc = expiresAtUtc;
    }

    public UserId UserId { get; private set; }

    public string RefreshTokenHash { get; private set; }

    public DateTimeOffset CreatedAtUtc { get; private set; }

    public DateTimeOffset ExpiresAtUtc { get; private set; }

    public DateTimeOffset? RevokedAtUtc { get; private set; }

    public bool IsRevoked => RevokedAtUtc.HasValue;

    public bool IsExpired(DateTimeOffset utcNow)
    {
        return utcNow >= ExpiresAtUtc;
    }

    public bool IsActive(DateTimeOffset utcNow)
    {
        return !IsRevoked && !IsExpired(utcNow);
    }

    public static Result<Session> Create(
        SessionId id,
        UserId userId,
        string refreshTokenHash,
        DateTimeOffset createdAtUtc,
        DateTimeOffset expiresAtUtc)
    {
        if (id.Value == Guid.Empty)
        {
            throw new ArgumentException(
                "The session identifier cannot be empty.",
                nameof(id));
        }

        if (userId.Value == Guid.Empty)
        {
            throw new ArgumentException(
                "The user identifier cannot be empty.",
                nameof(userId));
        }

        ArgumentException.ThrowIfNullOrWhiteSpace(
            refreshTokenHash);

        if (expiresAtUtc <= createdAtUtc)
        {
            throw new ArgumentException(
                "The session expiration must be after its creation.");
        }

        return Result<Session>.Success(
            new Session(
                id,
                userId,
                refreshTokenHash,
                createdAtUtc,
                expiresAtUtc));
    }

    public Result Revoke(DateTimeOffset revokedAtUtc)
    {
        if (IsRevoked)
        {
            return Result.Success();
        }

        RevokedAtUtc = revokedAtUtc;

        return Result.Success();
    }

    public Result RotateRefreshToken(
        string newRefreshTokenHash,
        DateTimeOffset newExpiresAtUtc,
        DateTimeOffset utcNow)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(
            newRefreshTokenHash);

        if (!IsActive(utcNow))
        {
            return Result.Failure(
                SessionErrors.Inactive);
        }

        if (newExpiresAtUtc <= utcNow)
        {
            return Result.Failure(
                SessionErrors.InvalidExpiration);
        }

        RefreshTokenHash = newRefreshTokenHash;
        ExpiresAtUtc = newExpiresAtUtc;

        return Result.Success();
    }
}