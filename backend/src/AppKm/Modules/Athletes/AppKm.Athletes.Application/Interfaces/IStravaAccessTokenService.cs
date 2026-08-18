using AppKm.Athletes.Domain.Aggregates.StravaConnections;

namespace AppKm.Athletes.Application.Interfaces;

public interface IStravaAccessTokenService
{
    Task<string> GetValidAccessTokenAsync(
        StravaConnection connection,
        CancellationToken cancellationToken);
}