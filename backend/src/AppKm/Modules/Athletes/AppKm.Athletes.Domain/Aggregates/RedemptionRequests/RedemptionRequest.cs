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

    public Guid? MerchantId { get; private set; }

    public int? ProposedPoints { get; private set; }

    public DateTimeOffset? MerchantProposedAtUtc { get; private set; }

    public DateTimeOffset? AthleteConfirmedAtUtc { get; private set; }

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
            if (Status != RedemptionRequestStatus.AwaitingAthleteConfirmation)
            {
                throw new InvalidOperationException(
                    "Only redemption requests awaiting athlete confirmation can be completed.");
            }

            if (AthleteConfirmedAtUtc is null)
            {
                throw new InvalidOperationException(
                    "The athlete must confirm the redemption before completion.");
            }

            Status = RedemptionRequestStatus.Completed;
            CompletedAtUtc = completedAtUtc;
        }
        public void Expire(
            DateTimeOffset expiredAtUtc)
        {
            if (Status != RedemptionRequestStatus.Pending)
            {
                throw new InvalidOperationException(
                    "Only pending redemption requests can expire.");
            }

            if (expiredAtUtc <= ExpiresAtUtc)
            {
                throw new InvalidOperationException(
                    "The redemption request has not expired yet.");
            }

            Status = RedemptionRequestStatus.Expired;
        }
        public void Cancel()
        {
            if (Status != RedemptionRequestStatus.Pending &&
                Status != RedemptionRequestStatus.AwaitingAthleteConfirmation)
            {
                throw new InvalidOperationException(
                    "Only pending redemption requests can be cancelled.");
            }

            Status = RedemptionRequestStatus.Cancelled;
        }

        public void ProposeByMerchant(
        Guid merchantId,
        int proposedPoints,
        DateTimeOffset proposedAtUtc)
    {
        if (Status != RedemptionRequestStatus.Pending)
        {
            throw new InvalidOperationException(
                "Only pending redemption requests can receive a merchant proposal.");
        }

        if (merchantId == Guid.Empty)
        {
            throw new ArgumentException(
                "MerchantId is required.",
                nameof(merchantId));
        }

        if (proposedPoints <= 0)
        {
            throw new ArgumentOutOfRangeException(
                nameof(proposedPoints),
                "Proposed points must be greater than zero.");
        }

        if (proposedAtUtc > ExpiresAtUtc)
        {
            throw new InvalidOperationException(
                "The redemption request has expired.");
        }

        MerchantId = merchantId;
        ProposedPoints = proposedPoints;
        MerchantProposedAtUtc = proposedAtUtc;
        Status = RedemptionRequestStatus.AwaitingAthleteConfirmation;
    }
    public void ConfirmByAthlete(
        DateTimeOffset confirmedAtUtc)
    {
        if (Status != RedemptionRequestStatus.AwaitingAthleteConfirmation)
        {
            throw new InvalidOperationException(
                "The redemption request is not awaiting athlete confirmation.");
        }

        AthleteConfirmedAtUtc = confirmedAtUtc;
    }

    public void RejectByAthlete(DateTimeOffset rejectedAtUtc)
        {
            if (Status != RedemptionRequestStatus.AwaitingAthleteConfirmation)
            {
                throw new InvalidOperationException(
                    "Only redemption requests awaiting athlete confirmation can be rejected.");
            }

            Status = RedemptionRequestStatus.Cancelled;
            CompletedAtUtc = rejectedAtUtc;
        }

}