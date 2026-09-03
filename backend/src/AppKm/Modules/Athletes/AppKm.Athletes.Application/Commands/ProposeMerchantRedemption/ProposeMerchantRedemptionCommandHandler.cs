using AppKm.Athletes.Application.Interfaces;
using AppKm.Athletes.Domain.Aggregates.Merchants;
using AppKm.Athletes.Domain.Aggregates.RedemptionRequests;
using Platform.SharedKernel.Errors;
using Platform.SharedKernel.Results;

namespace AppKm.Athletes.Application.Commands.ProposeMerchantRedemption;

public sealed class ProposeMerchantRedemptionCommandHandler
{
    private readonly IMerchantRepository _merchantRepository;
    private readonly IRedemptionRequestRepository _redemptionRequestRepository;
    private readonly IPointTransactionRepository _pointTransactionRepository;
    private readonly IAthleteUnitOfWork _unitOfWork;

    public ProposeMerchantRedemptionCommandHandler(
        IMerchantRepository merchantRepository,
        IRedemptionRequestRepository redemptionRequestRepository,
        IPointTransactionRepository pointTransactionRepository,
        IAthleteUnitOfWork unitOfWork)
    {
        _merchantRepository = merchantRepository;
        _redemptionRequestRepository = redemptionRequestRepository;
        _pointTransactionRepository = pointTransactionRepository;
        _unitOfWork = unitOfWork;
    }

    public async Task<Result<ProposeMerchantRedemptionResult>> HandleAsync(
        ProposeMerchantRedemptionCommand command,
        CancellationToken cancellationToken)
    {
        Merchant? merchant = await _merchantRepository.GetByUserIdAsync(
            command.UserId,
            cancellationToken);

        if (merchant is null)
            return Result<ProposeMerchantRedemptionResult>.Failure(
                new Error("Merchants.Profile.NotFound", "The merchant profile was not found."));

        if (merchant.Status != MerchantStatus.Active)
            return Result<ProposeMerchantRedemptionResult>.Failure(
                new Error("Merchants.Profile.NotActive", "The merchant is not active."));

        if (command.ProposedPoints <= 0)
            return Result<ProposeMerchantRedemptionResult>.Failure(
                new Error("Merchants.Redemption.InvalidPoints", "Proposed points must be greater than zero."));

        RedemptionRequest? request = await _redemptionRequestRepository.GetByCodeAsync(
            command.Code.Trim(),
            cancellationToken);

        if (request is null)
            return Result<ProposeMerchantRedemptionResult>.Failure(
                new Error("Merchants.Redemption.NotFound", "Redemption request was not found."));

        DateTimeOffset now = DateTimeOffset.UtcNow;

        if (request.Status == RedemptionRequestStatus.Pending && now > request.ExpiresAtUtc)
        {
            request.Expire(now);
            await _unitOfWork.SaveChangesAsync(cancellationToken);

            return Result<ProposeMerchantRedemptionResult>.Failure(
                new Error("Merchants.Redemption.Expired", "The redemption request has expired."));
        }

        if (request.Status != RedemptionRequestStatus.Pending)
            return Result<ProposeMerchantRedemptionResult>.Failure(
                new Error("Merchants.Redemption.NotPending", "The redemption request is no longer pending."));

        if (command.ProposedPoints != request.RequestedPoints)
            return Result<ProposeMerchantRedemptionResult>.Failure(
                new Error("Merchants.Redemption.AmountMismatch", "The redemption amount cannot be changed by the merchant."));

        int balance = await _pointTransactionRepository.GetBalanceAsync(
            request.AthleteId,
            cancellationToken);

        if (request.RequestedPoints > balance)
            return Result<ProposeMerchantRedemptionResult>.Failure(
                new Error("Merchants.Redemption.InsufficientBalance", "The athlete does not have enough points."));

        request.ProposeByMerchant(
            merchant.Id.Value,
            request.RequestedPoints,
            now);

        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return Result<ProposeMerchantRedemptionResult>.Success(
            new ProposeMerchantRedemptionResult(
                request.Id.Value,
                merchant.Id.Value,
                request.Code,
                request.ProposedPoints!.Value,
                request.Status.ToString(),
                request.MerchantProposedAtUtc!.Value));
    }
}
