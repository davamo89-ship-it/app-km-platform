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

    public Task<int> GetBalanceAsync(
        Guid athleteId,
        CancellationToken cancellationToken)
    {
        return _dbContext.PointTransactions
            .Where(transaction =>
                transaction.AthleteId == athleteId)
            .SumAsync(
                transaction =>
                    transaction.Type == PointTransactionType.Earned
                        ? transaction.Points
                        : transaction.Type == PointTransactionType.Redeemed ||
                          transaction.Type == PointTransactionType.Expired
                            ? -transaction.Points
                            : 0,
                cancellationToken);
    }

    public async Task<IReadOnlyList<PointTransaction>> GetHistoryAsync(
        Guid athleteId,
        CancellationToken cancellationToken)
    {
        return await _dbContext.PointTransactions
            .AsNoTracking()
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
            .AsNoTracking()
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
