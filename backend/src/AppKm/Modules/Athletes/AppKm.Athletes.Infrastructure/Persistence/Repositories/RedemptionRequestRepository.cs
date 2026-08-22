using AppKm.Athletes.Application.Interfaces;
using AppKm.Athletes.Domain.Aggregates.RedemptionRequests;
using Microsoft.EntityFrameworkCore;

namespace AppKm.Athletes.Infrastructure.Persistence.Repositories;

internal sealed class RedemptionRequestRepository
    : IRedemptionRequestRepository
{
    private readonly AthleteDbContext _dbContext;

    public RedemptionRequestRepository(
        AthleteDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public Task<RedemptionRequest?> GetByCodeAsync(
        string code,
        CancellationToken cancellationToken)
    {
        return _dbContext.RedemptionRequests
            .FirstOrDefaultAsync(
                request =>
                    request.Code == code,
                cancellationToken);
    }

    public Task<bool> ExistsByCodeAsync(
        string code,
        CancellationToken cancellationToken)
    {
        return _dbContext.RedemptionRequests
            .AnyAsync(
                request =>
                    request.Code == code,
                cancellationToken);
    }

    public async Task AddAsync(
        RedemptionRequest request,
        CancellationToken cancellationToken)
    {
        await _dbContext.RedemptionRequests.AddAsync(
            request,
            cancellationToken);
    }
}