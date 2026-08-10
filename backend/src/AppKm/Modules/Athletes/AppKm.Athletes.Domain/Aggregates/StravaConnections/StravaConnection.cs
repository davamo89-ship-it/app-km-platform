using Platform.SharedKernel.Entities;

namespace AppKm.Athletes.Domain.Aggregates.StravaConnections;

public sealed class StravaConnection
    : AggregateRoot<StravaConnectionId>
{
    private StravaConnection()
        : base(default)
    {
        AccessTokenEncrypted = string.Empty;
        RefreshTokenEncrypted = string.Empty;
    }

    private StravaConnection(
        StravaConnectionId id,
        Guid athleteId,
        long stravaAthleteId,
        string accessTokenEncrypted,
        string refreshTokenEncrypted,
        DateTimeOffset accessTokenExpiresAtUtc,
        DateTimeOffset connectedAtUtc)
        : base(id)
    {
        AthleteId = athleteId;
        StravaAthleteId = stravaAthleteId;
        AccessTokenEncrypted = accessTokenEncrypted;
        RefreshTokenEncrypted = refreshTokenEncrypted;
        AccessTokenExpiresAtUtc = accessTokenExpiresAtUtc;
        ConnectedAtUtc = connectedAtUtc;
        Status = StravaConnectionStatus.Active;
    }

    public Guid AthleteId { get; private set; }

    public long StravaAthleteId { get; private set; }

    public string AccessTokenEncrypted { get; private set; }

    public string RefreshTokenEncrypted { get; private set; }

    public DateTimeOffset AccessTokenExpiresAtUtc { get; private set; }

    public DateTimeOffset ConnectedAtUtc { get; private set; }

    public DateTimeOffset? UpdatedAtUtc { get; private set; }

    public StravaConnectionStatus Status { get; private set; }

    public static StravaConnection Create(
        StravaConnectionId id,
        Guid athleteId,
        long stravaAthleteId,
        string accessTokenEncrypted,
        string refreshTokenEncrypted,
        DateTimeOffset accessTokenExpiresAtUtc,
        DateTimeOffset connectedAtUtc)
    {
        if (id.Value == Guid.Empty)
        {
            throw new ArgumentException(
                "The Strava connection identifier cannot be empty.",
                nameof(id));
        }

        if (athleteId == Guid.Empty)
        {
            throw new ArgumentException(
                "The athlete identifier cannot be empty.",
                nameof(athleteId));
        }

        if (stravaAthleteId <= 0)
        {
            throw new ArgumentOutOfRangeException(
                nameof(stravaAthleteId));
        }

        ArgumentException.ThrowIfNullOrWhiteSpace(
            accessTokenEncrypted);

        ArgumentException.ThrowIfNullOrWhiteSpace(
            refreshTokenEncrypted);

        return new StravaConnection(
            id,
            athleteId,
            stravaAthleteId,
            accessTokenEncrypted,
            refreshTokenEncrypted,
            accessTokenExpiresAtUtc,
            connectedAtUtc);
    }

    public void RotateTokens(
        string accessTokenEncrypted,
        string refreshTokenEncrypted,
        DateTimeOffset accessTokenExpiresAtUtc,
        DateTimeOffset updatedAtUtc)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(
            accessTokenEncrypted);

        ArgumentException.ThrowIfNullOrWhiteSpace(
            refreshTokenEncrypted);

        AccessTokenEncrypted = accessTokenEncrypted;
        RefreshTokenEncrypted = refreshTokenEncrypted;
        AccessTokenExpiresAtUtc = accessTokenExpiresAtUtc;
        UpdatedAtUtc = updatedAtUtc;
        Status = StravaConnectionStatus.Active;
    }

    public void Revoke(
        DateTimeOffset updatedAtUtc)
    {
        Status = StravaConnectionStatus.Revoked;
        UpdatedAtUtc = updatedAtUtc;
    }
}