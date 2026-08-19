using AppKm.Athletes.Domain.Aggregates.PointTransactions;

namespace AppKm.Athletes.Application.Interfaces;

public interface IPointTransactionRepository
{
    Task<bool> ExistsEarnedForActivityAsync(
        Guid athleteId,
        Guid athleteActivityId,
        CancellationToken cancellationToken);

    Task AddAsync(
        PointTransaction transaction,
        CancellationToken cancellationToken);
    
    Task<int> GetBalanceAsync(
    Guid athleteId,
    CancellationToken cancellationToken);

    Task<IReadOnlyList<PointTransaction>> GetHistoryAsync(
    Guid athleteId,
    CancellationToken cancellationToken);

    Task<IReadOnlyList<PointTransaction>> GetAllByAthleteAsync(
    Guid athleteId,
    CancellationToken cancellationToken);

    Task<bool> ExistsExpiredForActivityAsync(
    Guid athleteId,
    Guid athleteActivityId,
    CancellationToken cancellationToken);
}