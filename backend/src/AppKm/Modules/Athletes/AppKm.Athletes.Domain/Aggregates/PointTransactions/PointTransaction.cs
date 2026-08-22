namespace AppKm.Athletes.Domain.Aggregates.PointTransactions;

public sealed class PointTransaction
{
    private PointTransaction()
    {
    }

    private PointTransaction(
        PointTransactionId id,
        Guid athleteId,
        Guid? athleteActivityId,
        PointTransactionType type,
        int points,
        DateTimeOffset createdAtUtc,
        DateTimeOffset? expiresAtUtc)
    {
        Id = id;
        AthleteId = athleteId;
        AthleteActivityId = athleteActivityId;
        Type = type;
        Points = points;
        CreatedAtUtc = createdAtUtc;
        ExpiresAtUtc = expiresAtUtc;
    }

    public PointTransactionId Id { get; private set; }

    public Guid AthleteId { get; private set; }

    public Guid? AthleteActivityId { get; private set; }

    public PointTransactionType Type { get; private set; }

    public int Points { get; private set; }

    public DateTimeOffset CreatedAtUtc { get; private set; }

    public DateTimeOffset? ExpiresAtUtc { get; private set; }

    public static PointTransaction CreateEarned(
        Guid athleteId,
        Guid athleteActivityId,
        int points,
        DateTimeOffset createdAtUtc)
    {
        if (athleteId == Guid.Empty)
        {
            throw new ArgumentException(
                "AthleteId is required.",
                nameof(athleteId));
        }

        if (athleteActivityId == Guid.Empty)
        {
            throw new ArgumentException(
                "AthleteActivityId is required.",
                nameof(athleteActivityId));
        }

        if (points <= 0)
        {
            throw new ArgumentOutOfRangeException(
                nameof(points),
                "Earned points must be greater than zero.");
        }

        return new PointTransaction(
            PointTransactionId.New(),
            athleteId,
            athleteActivityId,
            PointTransactionType.Earned,
            points,
            createdAtUtc,
            createdAtUtc.AddYears(1));
    }

        public static PointTransaction CreateExpired(
        Guid athleteId,
        Guid athleteActivityId,
        int points,
        DateTimeOffset createdAtUtc)
    {
        if (athleteId == Guid.Empty)
        {
            throw new ArgumentException(
                "AthleteId is required.",
                nameof(athleteId));
        }

        if (athleteActivityId == Guid.Empty)
        {
            throw new ArgumentException(
                "AthleteActivityId is required.",
                nameof(athleteActivityId));
        }

        if (points <= 0)
        {
            throw new ArgumentOutOfRangeException(
                nameof(points),
                "Expired points must be greater than zero.");
        }

        return new PointTransaction(
            PointTransactionId.New(),
            athleteId,
            athleteActivityId,
            PointTransactionType.Expired,
            points,
            createdAtUtc,
            null);
    }

    public static PointTransaction CreateRedeemed(
    Guid athleteId,
    int points,
    DateTimeOffset createdAtUtc)
{
    if (athleteId == Guid.Empty)
    {
        throw new ArgumentException(
            "AthleteId is required.",
            nameof(athleteId));
    }

    if (points <= 0)
    {
        throw new ArgumentOutOfRangeException(
            nameof(points),
            "Redeemed points must be greater than zero.");
    }

    return new PointTransaction(
        PointTransactionId.New(),
        athleteId,
        null,
        PointTransactionType.Redeemed,
        points,
        createdAtUtc,
        null);
}
}