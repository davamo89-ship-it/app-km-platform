namespace AppKm.Athletes.Application.Commands.CreateRedemptionRequest;

public sealed record CreateRedemptionRequestResult(
    Guid RedemptionRequestId,
    string Code,
    int RequestedPoints,
    string Status,
    DateTimeOffset CreatedAtUtc,
    DateTimeOffset ExpiresAtUtc);