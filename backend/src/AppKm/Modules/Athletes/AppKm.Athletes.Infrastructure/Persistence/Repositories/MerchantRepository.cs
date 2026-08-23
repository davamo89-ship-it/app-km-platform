using AppKm.Athletes.Application.Interfaces;
using AppKm.Athletes.Domain.Aggregates.Merchants;
using Microsoft.EntityFrameworkCore;

namespace AppKm.Athletes.Infrastructure.Persistence.Repositories;

internal sealed class MerchantRepository
    : IMerchantRepository
{
    private readonly AthleteDbContext _dbContext;

    public MerchantRepository(
        AthleteDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public Task<Merchant?> GetByIdAsync(
        MerchantId merchantId,
        CancellationToken cancellationToken)
    {
        return _dbContext.Merchants
            .FirstOrDefaultAsync(
                merchant =>
                    merchant.Id == merchantId,
                cancellationToken);
    }

    public Task<Merchant?> GetByUserIdAsync(
        Guid userId,
        CancellationToken cancellationToken)
    {
        return _dbContext.Merchants
            .FirstOrDefaultAsync(
                merchant =>
                    merchant.UserId == userId,
                cancellationToken);
    }

    public Task<bool> ExistsByUserIdAsync(
        Guid userId,
        CancellationToken cancellationToken)
    {
        return _dbContext.Merchants
            .AnyAsync(
                merchant =>
                    merchant.UserId == userId,
                cancellationToken);
    }

    public async Task AddAsync(
        Merchant merchant,
        CancellationToken cancellationToken)
    {
        await _dbContext.Merchants.AddAsync(
            merchant,
            cancellationToken);
    }
}