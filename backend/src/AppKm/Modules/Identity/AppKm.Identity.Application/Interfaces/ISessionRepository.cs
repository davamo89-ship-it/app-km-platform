using AppKm.Identity.Domain.Aggregates.Sessions;
using AppKm.Identity.Domain.Aggregates.Users;

namespace AppKm.Identity.Application.Interfaces;

public interface ISessionRepository
{
    Task<Session?> GetByRefreshTokenHashAsync(
        string refreshTokenHash,
        CancellationToken cancellationToken);

    Task<IReadOnlyCollection<Session>> GetActiveByUserIdAsync(
        UserId userId,
        DateTimeOffset utcNow,
        CancellationToken cancellationToken);

    Task AddAsync(
        Session session,
        CancellationToken cancellationToken);
}