namespace AppKm.Athletes.Application.Commands.ProposeMerchantRedemption;

public sealed record ProposeMerchantRedemptionCommand(
    Guid UserId,
    string Code,
    int ProposedPoints);
