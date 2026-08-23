using AppKm.Athletes.Domain.Aggregates.Merchants;

namespace AppKm.Athletes.Application.Interfaces;

public interface IMerchantRepository
{
    Task<Merchant?> GetByIdAsync(
        MerchantId merchantId,
        CancellationToken cancellationToken);

    Task<Merchant?> GetByUserIdAsync(
        Guid userId,
        CancellationToken cancellationToken);

    Task<bool> ExistsByUserIdAsync(
        Guid userId,
        CancellationToken cancellationToken);

    Task AddAsync(
        Merchant merchant,
        CancellationToken cancellationToken);
}