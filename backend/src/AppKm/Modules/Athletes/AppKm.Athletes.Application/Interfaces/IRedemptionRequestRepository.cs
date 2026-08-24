using AppKm.Athletes.Domain.Aggregates.RedemptionRequests;

namespace AppKm.Athletes.Application.Interfaces;

public interface IRedemptionRequestRepository
{
    Task<RedemptionRequest?> GetByCodeAsync(
        string code,
        CancellationToken cancellationToken);

    Task<bool> ExistsByCodeAsync(
        string code,
        CancellationToken cancellationToken);

    Task AddAsync(
        RedemptionRequest request,
        CancellationToken cancellationToken);

    Task<IReadOnlyList<RedemptionRequest>> GetByAthleteAsync(
        Guid athleteId,
        CancellationToken cancellationToken);
    Task<int> GetPendingReservedPointsAsync(
        Guid athleteId,
        DateTimeOffset now,
        CancellationToken cancellationToken);
    Task<RedemptionRequest?> GetPendingConfirmationByAthleteAsync(
        Guid athleteId,
        CancellationToken cancellationToken);
}