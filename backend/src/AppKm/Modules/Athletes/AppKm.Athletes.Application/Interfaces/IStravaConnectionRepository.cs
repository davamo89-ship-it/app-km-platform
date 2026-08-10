using AppKm.Athletes.Domain.Aggregates.StravaConnections;

namespace AppKm.Athletes.Application.Interfaces;

public interface IStravaConnectionRepository
{
    Task<StravaConnection?> GetByAthleteIdAsync(
        Guid athleteId,
        CancellationToken cancellationToken);

    Task<StravaConnection?> GetByStravaAthleteIdAsync(
        long stravaAthleteId,
        CancellationToken cancellationToken);

    Task<bool> ExistsByAthleteIdAsync(
        Guid athleteId,
        CancellationToken cancellationToken);

    Task AddAsync(
        StravaConnection connection,
        CancellationToken cancellationToken);
}
public interface IStravaAuthorizationService
{
    string BuildAuthorizationUrl(
        string state);
}