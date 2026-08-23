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

    public async Task<IReadOnlyList<RedemptionRequest>> GetByAthleteAsync(
            Guid athleteId,
            CancellationToken cancellationToken)
        {
            return await _dbContext.RedemptionRequests
                .Where(request =>
                    request.AthleteId == athleteId)
                .OrderByDescending(request =>
                    request.CreatedAtUtc)
                .ToListAsync(cancellationToken);
        }
    public Task<int> GetPendingReservedPointsAsync(
    Guid athleteId,
    DateTimeOffset now,
    CancellationToken cancellationToken)
        {
            return _dbContext.RedemptionRequests
                .Where(request =>
                    request.AthleteId == athleteId &&
                    request.Status == RedemptionRequestStatus.Pending &&
                    request.ExpiresAtUtc > now)
                .SumAsync(
                    request => request.RequestedPoints,
                    cancellationToken);
        }
}