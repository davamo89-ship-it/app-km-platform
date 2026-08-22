namespace AppKm.Athletes.Domain.Aggregates.RedemptionRequests;

public enum RedemptionRequestStatus
{
    Pending = 1,
    Completed = 2,
    Cancelled = 3,
    Expired = 4
}