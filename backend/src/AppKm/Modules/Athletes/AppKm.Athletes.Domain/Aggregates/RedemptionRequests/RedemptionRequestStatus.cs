namespace AppKm.Athletes.Domain.Aggregates.RedemptionRequests;

public enum RedemptionRequestStatus
{
    Pending = 1,
    AwaitingAthleteConfirmation = 2,
    Completed = 3,
    Cancelled = 4,
    Expired = 5
}