namespace AppKm.Athletes.Application.Commands.RejectAthleteRedemption;

public sealed record RejectAthleteRedemptionCommand(
    Guid UserId,
    string Code);