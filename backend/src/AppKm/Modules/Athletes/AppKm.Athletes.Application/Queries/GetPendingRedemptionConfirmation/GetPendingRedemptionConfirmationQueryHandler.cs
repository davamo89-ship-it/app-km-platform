using AppKm.Athletes.Application.Interfaces;
using AppKm.Athletes.Domain.Aggregates.Athletes;
using AppKm.Athletes.Domain.Aggregates.Merchants;
using AppKm.Athletes.Domain.Aggregates.RedemptionRequests;
using Platform.SharedKernel.Errors;
using Platform.SharedKernel.Results;

namespace AppKm.Athletes.Application.Queries.GetPendingRedemptionConfirmation;

public sealed class GetPendingRedemptionConfirmationQueryHandler
{
    private readonly IAthleteRepository _athleteRepository;
    private readonly IRedemptionRequestRepository _redemptionRequestRepository;
    private readonly IMerchantRepository _merchantRepository;

    public GetPendingRedemptionConfirmationQueryHandler(
        IAthleteRepository athleteRepository,
        IRedemptionRequestRepository redemptionRequestRepository,
        IMerchantRepository merchantRepository)
    {
        _athleteRepository = athleteRepository;
        _redemptionRequestRepository = redemptionRequestRepository;
        _merchantRepository = merchantRepository;
    }

    public async Task<Result<GetPendingRedemptionConfirmationResult?>> HandleAsync(
        Guid userId,
        CancellationToken cancellationToken)
    {
        Athlete? athlete =
            await _athleteRepository.GetByUserIdAsync(
                userId,
                cancellationToken);

        if (athlete is null)
        {
            return Result<GetPendingRedemptionConfirmationResult?>.Failure(
                new Error(
                    "Athletes.Profile.NotFound",
                    "The athlete profile was not found."));
        }

        RedemptionRequest? request =
            await _redemptionRequestRepository
                .GetPendingConfirmationByAthleteAsync(
                    athlete.Id.Value,
                    cancellationToken);

        if (request is null)
        {
           return Result<GetPendingRedemptionConfirmationResult>.Failure(
        new Error(
            "Athletes.Redemption.NoPendingConfirmation",
            "There is no redemption awaiting athlete confirmation."));
        }

        if (request.MerchantId is null ||
            request.ProposedPoints is null ||
            request.MerchantProposedAtUtc is null)
        {
            return Result<GetPendingRedemptionConfirmationResult?>.Failure(
                new Error(
                    "Athletes.Redemption.InvalidProposal",
                    "The redemption proposal is incomplete."));
        }

        Merchant? merchant =
            await _merchantRepository.GetByIdAsync(
                new MerchantId(request.MerchantId.Value),
                cancellationToken);

        if (merchant is null)
        {
            return Result<GetPendingRedemptionConfirmationResult?>.Failure(
                new Error(
                    "Merchants.Profile.NotFound",
                    "The merchant profile was not found."));
        }

        return Result<GetPendingRedemptionConfirmationResult?>.Success(
            new GetPendingRedemptionConfirmationResult(
                request.Id.Value,
                request.Code,
                merchant.Id.Value,
                merchant.BusinessName,
                request.ProposedPoints.Value,
                request.Status.ToString(),
                request.MerchantProposedAtUtc.Value,
                request.ExpiresAtUtc));
    }
}