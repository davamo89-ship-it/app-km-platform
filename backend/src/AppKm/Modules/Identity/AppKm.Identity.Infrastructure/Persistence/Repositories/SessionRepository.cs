using AppKm.Identity.Application.Interfaces;
using AppKm.Identity.Domain.Aggregates.Sessions;
using AppKm.Identity.Domain.Aggregates.Users;
using Microsoft.EntityFrameworkCore;

namespace AppKm.Identity.Infrastructure.Persistence.Repositories;

internal sealed class SessionRepository
    : ISessionRepository
{
    private readonly IdentityDbContext _dbContext;

    public SessionRepository(
        IdentityDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public Task<Session?> GetByRefreshTokenHashAsync(
        string refreshTokenHash,
        CancellationToken cancellationToken)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(
            refreshTokenHash);

        return _dbContext.Sessions
            .SingleOrDefaultAsync(
                session =>
                    session.RefreshTokenHash ==
                    refreshTokenHash,
                cancellationToken);
    }

    public async Task<IReadOnlyCollection<Session>>
        GetActiveByUserIdAsync(
            UserId userId,
            DateTimeOffset utcNow,
            CancellationToken cancellationToken)
    {
        return await _dbContext.Sessions
            .Where(session =>
                session.UserId == userId &&
                session.RevokedAtUtc == null &&
                session.ExpiresAtUtc > utcNow)
            .ToListAsync(cancellationToken);
    }

    public async Task AddAsync(
        Session session,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(session);

        await _dbContext.Sessions.AddAsync(
            session,
            cancellationToken);
    }
}