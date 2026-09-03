using AppKm.Athletes.Application.Interfaces;
using AppKm.Athletes.Domain.Aggregates.Athletes;
using Platform.SharedKernel.Errors;
using Platform.SharedKernel.Results;
using AppKm.Athletes.Domain.Aggregates.RedemptionRequests;
using AppKm.Athletes.Domain.Aggregates.Merchants;

namespace AppKm.Athletes.Application.Queries.GetRedemptionRequests;

public sealed class GetRedemptionRequestsQueryHandler
{
    private readonly IAthleteRepository _athleteRepository;
    private readonly IRedemptionRequestRepository _redemptionRequestRepository;
    private readonly IAthleteUnitOfWork _unitOfWork;
    private readonly IMerchantRepository _merchantRepository;

    public GetRedemptionRequestsQueryHandler(
        IAthleteRepository athleteRepository,
        IRedemptionRequestRepository redemptionRequestRepository,
        IAthleteUnitOfWork unitOfWork,
        IMerchantRepository merchantRepository)
    {
        _athleteRepository = athleteRepository;
        _redemptionRequestRepository = redemptionRequestRepository;
        _unitOfWork = unitOfWork;
        _merchantRepository = merchantRepository;
    }

    public async Task<Result<IReadOnlyList<GetRedemptionRequestItem>>> HandleAsync(
        Guid userId,
        CancellationToken cancellationToken)
    {
        Athlete? athlete =
            await _athleteRepository.GetByUserIdAsync(
                userId,
                cancellationToken);

        if (athlete is null)
        {
            return Result<IReadOnlyList<GetRedemptionRequestItem>>.Failure(
                new Error(
                    "Athletes.Profile.NotFound",
                    "The athlete profile was not found."));
        }

        var requests =
            await _redemptionRequestRepository.GetByAthleteAsync(
                athlete.Id.Value,
                cancellationToken);
        
        DateTimeOffset now =
            DateTimeOffset.UtcNow;

        bool hasExpiredRequests = false;

        foreach (var request in requests)
        {
            if (request.Status == RedemptionRequestStatus.Pending &&
                now > request.ExpiresAtUtc)
            {
                request.Expire(now);
                hasExpiredRequests = true;
            }
        }

        if (hasExpiredRequests)
        {
            await _unitOfWork.SaveChangesAsync(
                cancellationToken);
        }


        var merchantNames = new Dictionary<Guid, string>();

        foreach (Guid merchantId in requests
                     .Where(request => request.MerchantId.HasValue)
                     .Select(request => request.MerchantId!.Value)
                     .Distinct())
        {
            Merchant? merchant = await _merchantRepository.GetByIdAsync(
                new MerchantId(merchantId),
                cancellationToken);

            if (merchant is not null)
            {
                merchantNames[merchantId] = merchant.BusinessName;
            }
        }

        var items =
            requests
                .Select(request =>
                {
                    string? merchantName = null;

                    if (request.MerchantId.HasValue)
                    {
                        merchantNames.TryGetValue(
                            request.MerchantId.Value,
                            out merchantName);
                    }

                    return new GetRedemptionRequestItem(
                        request.Id.Value,
                        request.Code,
                        request.RequestedPoints,
                        request.Status.ToString(),
                        request.CreatedAtUtc,
                        request.ExpiresAtUtc,
                        request.CompletedAtUtc,
                        request.MerchantId,
                        merchantName);
                })
                .ToList();

        return Result<IReadOnlyList<GetRedemptionRequestItem>>.Success(
            items);
    }
}
