using AppKm.Athletes.Application.Interfaces;
using AppKm.Athletes.Domain.Aggregates.Athletes;
using AppKm.Athletes.Domain.Aggregates.Merchants;
using AppKm.Athletes.Domain.Aggregates.RedemptionRequests;
using Platform.SharedKernel.Errors;
using Platform.SharedKernel.Results;

namespace AppKm.Athletes.Application.Queries.GetLatestMerchantRedemption;

public sealed class GetLatestMerchantRedemptionQueryHandler
{
    private readonly IMerchantRepository _merchantRepository;
    private readonly IRedemptionRequestRepository
        _redemptionRequestRepository;
    private readonly IAthleteRepository _athleteRepository;

    public GetLatestMerchantRedemptionQueryHandler(
        IMerchantRepository merchantRepository,
        IRedemptionRequestRepository redemptionRequestRepository,
        IAthleteRepository athleteRepository)
    {
        _merchantRepository = merchantRepository;
        _redemptionRequestRepository =
            redemptionRequestRepository;
        _athleteRepository = athleteRepository;
    }

    public async Task<Result<GetLatestMerchantRedemptionResult?>>
        HandleAsync(
            Guid userId,
            CancellationToken cancellationToken)
    {
        Merchant? merchant =
            await _merchantRepository.GetByUserIdAsync(
                userId,
                cancellationToken);

        if (merchant is null)
        {
            return Result<GetLatestMerchantRedemptionResult?>.Failure(
                new Error(
                    "Merchants.Profile.NotFound",
                    "The merchant profile was not found."));
        }

        RedemptionRequest? request =
            await _redemptionRequestRepository
                .GetLatestByMerchantAsync(
                    merchant.Id.Value,
                    cancellationToken);

        if (request is null)
        {
            return Result<GetLatestMerchantRedemptionResult?>.Success(
                null);
        }

        Athlete? athlete =
            await _athleteRepository.GetByIdAsync(
                AthleteId.From(request.AthleteId),
                cancellationToken);

        string athleteDisplayName =
            athlete?.DisplayName ?? "Atleta";

        int points =
            request.ProposedPoints ??
            request.RequestedPoints;

        var result =
            new GetLatestMerchantRedemptionResult(
                request.Id.Value,
                request.Code,
                request.AthleteId,
                athleteDisplayName,
                points,
                request.Status.ToString(),
                request.CreatedAtUtc,
                request.MerchantProposedAtUtc,
                request.CompletedAtUtc);

        return Result<GetLatestMerchantRedemptionResult?>.Success(
            result);
    }
}
