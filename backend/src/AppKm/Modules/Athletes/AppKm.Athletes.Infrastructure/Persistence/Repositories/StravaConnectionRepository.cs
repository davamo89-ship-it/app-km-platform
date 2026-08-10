using AppKm.Athletes.Application.Interfaces;
using AppKm.Athletes.Domain.Aggregates.StravaConnections;
using Microsoft.EntityFrameworkCore;

namespace AppKm.Athletes.Infrastructure.Persistence.Repositories;

internal sealed class StravaConnectionRepository
    : IStravaConnectionRepository
{
    private readonly AthleteDbContext _dbContext;

    public StravaConnectionRepository(
        AthleteDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public Task<StravaConnection?> GetByAthleteIdAsync(
        Guid athleteId,
        CancellationToken cancellationToken)
    {
        return _dbContext.StravaConnections
            .SingleOrDefaultAsync(
                connection =>
                    connection.AthleteId == athleteId,
                cancellationToken);
    }

    public Task<StravaConnection?> GetByStravaAthleteIdAsync(
        long stravaAthleteId,
        CancellationToken cancellationToken)
    {
        return _dbContext.StravaConnections
            .SingleOrDefaultAsync(
                connection =>
                    connection.StravaAthleteId ==
                    stravaAthleteId,
                cancellationToken);
    }

    public Task<bool> ExistsByAthleteIdAsync(
        Guid athleteId,
        CancellationToken cancellationToken)
    {
        return _dbContext.StravaConnections
            .AnyAsync(
                connection =>
                    connection.AthleteId == athleteId,
                cancellationToken);
    }

    public async Task AddAsync(
        StravaConnection connection,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(connection);

        await _dbContext.StravaConnections.AddAsync(
            connection,
            cancellationToken);
    }
}