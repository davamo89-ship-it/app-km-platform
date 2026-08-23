namespace AppKm.Athletes.Application.Queries.GetRedemptionRequests;

public sealed record GetRedemptionRequestItem(
    Guid RedemptionRequestId,
    string Code,
    int RequestedPoints,
    string Status,
    DateTimeOffset CreatedAtUtc,
    DateTimeOffset ExpiresAtUtc,
    DateTimeOffset? CompletedAtUtc);