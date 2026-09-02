using AppKm.Athletes.Application.Interfaces;
using AppKm.Athletes.Domain.Aggregates.Athletes;
using AppKm.Athletes.Domain.Aggregates.Merchants;
using AppKm.Athletes.Domain.Aggregates.RedemptionRequests;
using Platform.SharedKernel.Errors;
using Platform.SharedKernel.Results;

namespace AppKm.Athletes.Application.Queries.GetMerchantRedemptionHistory;

public sealed class GetMerchantRedemptionHistoryQueryHandler
{
    private const int HistoryLimit = 20;

    private readonly IMerchantRepository _merchantRepository;
    private readonly IRedemptionRequestRepository _redemptionRequestRepository;
    private readonly IAthleteRepository _athleteRepository;

    public GetMerchantRedemptionHistoryQueryHandler(
        IMerchantRepository merchantRepository,
        IRedemptionRequestRepository redemptionRequestRepository,
        IAthleteRepository athleteRepository)
    {
        _merchantRepository = merchantRepository;
        _redemptionRequestRepository = redemptionRequestRepository;
        _athleteRepository = athleteRepository;
    }

    public async Task<Result<IReadOnlyList<GetMerchantRedemptionHistoryResult>>> HandleAsync(
        Guid userId,
        CancellationToken cancellationToken)
    {
        Merchant? merchant = await _merchantRepository.GetByUserIdAsync(
            userId,
            cancellationToken);

        if (merchant is null)
        {
            return Result<IReadOnlyList<GetMerchantRedemptionHistoryResult>>.Failure(
                new Error(
                    "Merchants.Profile.NotFound",
                    "The merchant profile was not found."));
        }

        IReadOnlyList<RedemptionRequest> requests =
            await _redemptionRequestRepository.GetByMerchantAsync(
                merchant.Id.Value,
                HistoryLimit,
                cancellationToken);

        var items = new List<GetMerchantRedemptionHistoryResult>(requests.Count);

        foreach (RedemptionRequest request in requests)
        {
            Athlete? athlete = await _athleteRepository.GetByIdAsync(
                AthleteId.From(request.AthleteId),
                cancellationToken);

            items.Add(new GetMerchantRedemptionHistoryResult(
                request.Id.Value,
                request.Code,
                request.AthleteId,
                athlete?.DisplayName ?? "Atleta",
                request.ProposedPoints ?? request.RequestedPoints,
                request.Status.ToString(),
                request.CreatedAtUtc,
                request.MerchantProposedAtUtc,
                request.CompletedAtUtc));
        }

        return Result<IReadOnlyList<GetMerchantRedemptionHistoryResult>>.Success(items);
    }
}
