using AppKm.Athletes.Application.Interfaces;
using AppKm.Athletes.Domain.Aggregates.Merchants;
using Platform.SharedKernel.Errors;
using Platform.SharedKernel.Results;

namespace AppKm.Athletes.Application.Queries.GetMerchantProfile;

public sealed class GetMerchantProfileQueryHandler
{
    private readonly IMerchantRepository _merchantRepository;

    public GetMerchantProfileQueryHandler(
        IMerchantRepository merchantRepository)
    {
        _merchantRepository = merchantRepository;
    }

    public async Task<Result<GetMerchantProfileResult>> HandleAsync(
        GetMerchantProfileQuery query,
        CancellationToken cancellationToken)
    {
        Merchant? merchant =
            await _merchantRepository.GetByUserIdAsync(
                query.UserId,
                cancellationToken);

        if (merchant is null)
        {
            return Result<GetMerchantProfileResult>.Failure(
                new Error(
                    "Merchants.Profile.NotFound",
                    "The merchant profile was not found."));
        }

        return Result<GetMerchantProfileResult>.Success(
            new GetMerchantProfileResult(
                merchant.Id.Value,
                merchant.UserId,
                merchant.BusinessName,
                merchant.Status.ToString(),
                merchant.CreatedAtUtc,
                merchant.UpdatedAtUtc));
    }
}
