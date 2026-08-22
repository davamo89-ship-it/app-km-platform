namespace AppKm.Athletes.Application.Commands.CreateRedemptionRequest;

public sealed record CreateRedemptionRequestCommand(
    Guid UserId,
    int RequestedPoints);