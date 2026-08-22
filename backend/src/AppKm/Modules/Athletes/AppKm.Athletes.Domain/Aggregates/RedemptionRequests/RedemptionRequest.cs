using Platform.SharedKernel.Entities;

namespace AppKm.Athletes.Domain.Aggregates.RedemptionRequests;

public sealed class RedemptionRequest
    : AggregateRoot<RedemptionRequestId>
{
    private RedemptionRequest()
        : base(default)
    {
        Code = string.Empty;
    }

    private RedemptionRequest(
        RedemptionRequestId id,
        Guid athleteId,
        string code,
        int requestedPoints,
        DateTimeOffset createdAtUtc,
        DateTimeOffset expiresAtUtc)
        : base(id)
    {
        AthleteId = athleteId;
        Code = code;
        RequestedPoints = requestedPoints;
        Status = RedemptionRequestStatus.Pending;
        CreatedAtUtc = createdAtUtc;
        ExpiresAtUtc = expiresAtUtc;
    }

    public Guid AthleteId { get; private set; }

    public string Code { get; private set; }

    public int RequestedPoints { get; private set; }

    public RedemptionRequestStatus Status { get; private set; }

    public DateTimeOffset CreatedAtUtc { get; private set; }

    public DateTimeOffset ExpiresAtUtc { get; private set; }

    public DateTimeOffset? CompletedAtUtc { get; private set; }

    public static RedemptionRequest Create(
        Guid athleteId,
        string code,
        int requestedPoints,
        DateTimeOffset createdAtUtc,
        DateTimeOffset expiresAtUtc)
    {
        if (athleteId == Guid.Empty)
        {
            throw new ArgumentException(
                "AthleteId is required.",
                nameof(athleteId));
        }

        ArgumentException.ThrowIfNullOrWhiteSpace(code);

        if (requestedPoints <= 0)
        {
            throw new ArgumentOutOfRangeException(
                nameof(requestedPoints));
        }

        if (expiresAtUtc <= createdAtUtc)
        {
            throw new ArgumentException(
                "Expiration must be after creation.",
                nameof(expiresAtUtc));
        }

        return new RedemptionRequest(
            RedemptionRequestId.New(),
            athleteId,
            code.Trim(),
            requestedPoints,
            createdAtUtc,
            expiresAtUtc);
    }

    public void Complete(
        DateTimeOffset completedAtUtc)
    {
        if (Status != RedemptionRequestStatus.Pending)
        {
            throw new InvalidOperationException(
                "Only pending redemption requests can be completed.");
        }

        if (completedAtUtc > ExpiresAtUtc)
        {
            throw new InvalidOperationException(
                "The redemption request has expired.");
        }

        Status = RedemptionRequestStatus.Completed;
        CompletedAtUtc = completedAtUtc;
    }
}