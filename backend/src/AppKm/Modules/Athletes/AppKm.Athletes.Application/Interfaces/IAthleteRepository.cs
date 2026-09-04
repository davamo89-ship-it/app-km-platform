using AppKm.Athletes.Domain.Aggregates.Athletes;

namespace AppKm.Athletes.Application.Interfaces;

public interface IAthleteRepository
{
    Task<Athlete?> GetByIdAsync(
        AthleteId athleteId,
        CancellationToken cancellationToken);

    Task<Athlete?> GetByUserIdAsync(
        Guid userId,
        CancellationToken cancellationToken);

    Task<bool> ExistsByUserIdAsync(
        Guid userId,
        CancellationToken cancellationToken);

    Task<IReadOnlyList<Athlete>> GetAllAsync(
        CancellationToken cancellationToken);

    Task AddAsync(
        Athlete athlete,
        CancellationToken cancellationToken);
}
