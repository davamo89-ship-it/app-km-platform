namespace AppKm.Athletes.Application.Commands.CancelRedemption;

public sealed record CancelRedemptionCommand(
    Guid UserId,
    string Code);