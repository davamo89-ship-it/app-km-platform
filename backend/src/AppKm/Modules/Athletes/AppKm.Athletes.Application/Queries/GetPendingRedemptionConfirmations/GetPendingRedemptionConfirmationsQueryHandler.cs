using AppKm.Athletes.Application.Interfaces;
using AppKm.Athletes.Domain.Aggregates.Athletes;
using AppKm.Athletes.Domain.Aggregates.Merchants;
using AppKm.Athletes.Domain.Aggregates.RedemptionRequests;
using Platform.SharedKernel.Errors;
using Platform.SharedKernel.Results;

namespace AppKm.Athletes.Application.Queries.GetPendingRedemptionConfirmations;

public sealed class GetPendingRedemptionConfirmationsQueryHandler
{
    private readonly IAthleteRepository _athleteRepository;
    private readonly IRedemptionRequestRepository _redemptionRequestRepository;
    private readonly IMerchantRepository _merchantRepository;

    public GetPendingRedemptionConfirmationsQueryHandler(
        IAthleteRepository athleteRepository,
        IRedemptionRequestRepository redemptionRequestRepository,
        IMerchantRepository merchantRepository)
    {
        _athleteRepository = athleteRepository;
        _redemptionRequestRepository = redemptionRequestRepository;
        _merchantRepository = merchantRepository;
    }

    public async Task<Result<IReadOnlyList<GetPendingRedemptionConfirmationsResult>>>
        HandleAsync(
            Guid userId,
            CancellationToken cancellationToken)
    {
        Athlete? athlete =
            await _athleteRepository.GetByUserIdAsync(
                userId,
                cancellationToken);

        if (athlete is null)
        {
            return Result<IReadOnlyList<GetPendingRedemptionConfirmationsResult>>.Failure(
                new Error(
                    "Athletes.Profile.NotFound",
                    "The athlete profile was not found."));
        }

        IReadOnlyList<RedemptionRequest> requests =
            await _redemptionRequestRepository.GetByAthleteAsync(
                athlete.Id.Value,
                cancellationToken);

        var pendingRequests = requests
            .Where(request =>
                request.Status ==
                    RedemptionRequestStatus.AwaitingAthleteConfirmation)
            .OrderByDescending(request =>
                request.MerchantProposedAtUtc)
            .ToList();

        if (pendingRequests.Count == 0)
        {
            return Result<IReadOnlyList<GetPendingRedemptionConfirmationsResult>>.Success(
                Array.Empty<GetPendingRedemptionConfirmationsResult>());
        }

        var results =
            new List<GetPendingRedemptionConfirmationsResult>(
                pendingRequests.Count);

        foreach (RedemptionRequest request in pendingRequests)
        {
            if (request.MerchantId is null ||
                request.ProposedPoints is null ||
                request.MerchantProposedAtUtc is null)
            {
                return Result<IReadOnlyList<GetPendingRedemptionConfirmationsResult>>.Failure(
                    new Error(
                        "Athletes.Redemption.InvalidProposal",
                        "A redemption proposal is incomplete."));
            }

            Merchant? merchant =
                await _merchantRepository.GetByIdAsync(
                    new MerchantId(request.MerchantId.Value),
                    cancellationToken);

            if (merchant is null)
            {
                return Result<IReadOnlyList<GetPendingRedemptionConfirmationsResult>>.Failure(
                    new Error(
                        "Merchants.Profile.NotFound",
                        "A merchant profile was not found."));
            }

            results.Add(
                new GetPendingRedemptionConfirmationsResult(
                    request.Id.Value,
                    request.Code,
                    merchant.Id.Value,
                    merchant.BusinessName,
                    request.ProposedPoints.Value,
                    request.Status.ToString(),
                    request.MerchantProposedAtUtc.Value,
                    request.ExpiresAtUtc));
        }

        return Result<IReadOnlyList<GetPendingRedemptionConfirmationsResult>>.Success(
            results);
    }
}
