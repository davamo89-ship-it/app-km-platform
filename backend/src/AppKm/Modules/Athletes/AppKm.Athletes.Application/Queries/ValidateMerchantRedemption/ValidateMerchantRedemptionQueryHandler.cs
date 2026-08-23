using AppKm.Athletes.Application.Interfaces;
using AppKm.Athletes.Domain.Aggregates.Merchants;
using AppKm.Athletes.Domain.Aggregates.RedemptionRequests;
using Platform.SharedKernel.Errors;
using Platform.SharedKernel.Results;

namespace AppKm.Athletes.Application.Queries.ValidateMerchantRedemption;

public sealed class ValidateMerchantRedemptionQueryHandler
{
    private readonly IMerchantRepository _merchantRepository;
    private readonly IRedemptionRequestRepository _redemptionRequestRepository;
    private readonly IAthleteUnitOfWork _unitOfWork;

    public ValidateMerchantRedemptionQueryHandler(
        IMerchantRepository merchantRepository,
        IRedemptionRequestRepository redemptionRequestRepository,
        IAthleteUnitOfWork unitOfWork)
    {
        _merchantRepository = merchantRepository;
        _redemptionRequestRepository = redemptionRequestRepository;
        _unitOfWork = unitOfWork;
    }

    public async Task<Result<ValidateMerchantRedemptionResult>> HandleAsync(
        Guid userId,
        string code,
        CancellationToken cancellationToken)
    {
        Merchant? merchant =
            await _merchantRepository.GetByUserIdAsync(
                userId,
                cancellationToken);

        if (merchant is null)
        {
            return Result<ValidateMerchantRedemptionResult>.Failure(
                new Error(
                    "Merchants.Profile.NotFound",
                    "The merchant profile was not found."));
        }

        if (merchant.Status != MerchantStatus.Active)
        {
            return Result<ValidateMerchantRedemptionResult>.Failure(
                new Error(
                    "Merchants.Profile.NotActive",
                    "The merchant is not active."));
        }

        if (string.IsNullOrWhiteSpace(code))
        {
            return Result<ValidateMerchantRedemptionResult>.Failure(
                new Error(
                    "Merchants.Redemption.InvalidCode",
                    "Redemption code is required."));
        }

        RedemptionRequest? request =
            await _redemptionRequestRepository.GetByCodeAsync(
                code.Trim(),
                cancellationToken);

        if (request is null)
        {
            return Result<ValidateMerchantRedemptionResult>.Failure(
                new Error(
                    "Merchants.Redemption.NotFound",
                    "Redemption request was not found."));
        }

        DateTimeOffset now =
            DateTimeOffset.UtcNow;

        if (request.Status == RedemptionRequestStatus.Pending &&
            now > request.ExpiresAtUtc)
        {
            request.Expire(now);

            await _unitOfWork.SaveChangesAsync(
                cancellationToken);

            return Result<ValidateMerchantRedemptionResult>.Failure(
                new Error(
                    "Merchants.Redemption.Expired",
                    "The redemption request has expired."));
        }

        if (request.Status != RedemptionRequestStatus.Pending)
        {
            return Result<ValidateMerchantRedemptionResult>.Failure(
                new Error(
                    "Merchants.Redemption.NotPending",
                    "The redemption request is no longer pending."));
        }

        return Result<ValidateMerchantRedemptionResult>.Success(
            new ValidateMerchantRedemptionResult(
                request.Id.Value,
                request.Code,
                request.RequestedPoints,
                request.Status.ToString(),
                request.CreatedAtUtc,
                request.ExpiresAtUtc));
    }
}