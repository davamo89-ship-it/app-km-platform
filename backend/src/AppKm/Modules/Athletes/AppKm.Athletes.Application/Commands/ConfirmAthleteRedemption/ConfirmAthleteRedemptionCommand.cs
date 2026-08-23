namespace AppKm.Athletes.Application.Commands.ConfirmAthleteRedemption;

public sealed record ConfirmAthleteRedemptionCommand(
    Guid UserId,
    string Code);