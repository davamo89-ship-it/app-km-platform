using AppKm.Athletes.Application.Interfaces;
using AppKm.Athletes.Domain.Aggregates.PointTransactions;
using Microsoft.EntityFrameworkCore;

namespace AppKm.Athletes.Infrastructure.Persistence.Repositories;

internal sealed class PointTransactionRepository
    : IPointTransactionRepository
{
    private readonly AthleteDbContext _dbContext;

    public PointTransactionRepository(
        AthleteDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public Task<bool> ExistsEarnedForActivityAsync(
        Guid athleteId,
        Guid athleteActivityId,
        CancellationToken cancellationToken)
    {
        return _dbContext.PointTransactions.AnyAsync(
            transaction =>
                transaction.AthleteId == athleteId &&
                transaction.AthleteActivityId == athleteActivityId &&
                transaction.Type == PointTransactionType.Earned,
            cancellationToken);
    }

    public async Task AddAsync(
        PointTransaction transaction,
        CancellationToken cancellationToken)
    {
        await _dbContext.PointTransactions.AddAsync(
            transaction,
            cancellationToken);
    }

    public async Task<int> GetBalanceAsync(
    Guid athleteId,
    CancellationToken cancellationToken)
{
    int earned =
        await _dbContext.PointTransactions
            .Where(transaction =>
                transaction.AthleteId == athleteId &&
                transaction.Type == PointTransactionType.Earned)
            .SumAsync(
                transaction => (int?)transaction.Points,
                cancellationToken)
        ?? 0;

    int redeemed =
        await _dbContext.PointTransactions
            .Where(transaction =>
                transaction.AthleteId == athleteId &&
                transaction.Type == PointTransactionType.Redeemed)
            .SumAsync(
                transaction => (int?)transaction.Points,
                cancellationToken)
        ?? 0;

    int expired =
        await _dbContext.PointTransactions
            .Where(transaction =>
                transaction.AthleteId == athleteId &&
                transaction.Type == PointTransactionType.Expired)
            .SumAsync(
                transaction => (int?)transaction.Points,
                cancellationToken)
        ?? 0;

    return earned - redeemed - expired;
}

    public async Task<IReadOnlyList<PointTransaction>> GetHistoryAsync(
        Guid athleteId,
        CancellationToken cancellationToken)
    {
        return await _dbContext.PointTransactions
            .Where(transaction =>
                transaction.AthleteId == athleteId)
            .OrderByDescending(transaction =>
                transaction.CreatedAtUtc)
            .ToListAsync(cancellationToken);
    }

    public async Task<IReadOnlyList<PointTransaction>> GetAllByAthleteAsync(
        Guid athleteId,
        CancellationToken cancellationToken)
    {
        return await _dbContext.PointTransactions
            .Where(transaction =>
                transaction.AthleteId == athleteId)
            .OrderBy(transaction =>
                transaction.CreatedAtUtc)
            .ToListAsync(cancellationToken);
    }

    public Task<bool> ExistsExpiredForActivityAsync(
        Guid athleteId,
        Guid athleteActivityId,
        CancellationToken cancellationToken)
        {
            return _dbContext.PointTransactions.AnyAsync(
                transaction =>
                    transaction.AthleteId == athleteId &&
                    transaction.AthleteActivityId == athleteActivityId &&
                    transaction.Type == PointTransactionType.Expired,
                cancellationToken);
        }

}