namespace AppKm.Athletes.Application.Interfaces;

public interface IStravaActivitiesClient
{
    Task<IReadOnlyList<StravaActivityResult>> GetActivitiesAsync(
        string accessToken,
        DateTimeOffset? after,
        DateTimeOffset? before,
        int page,
        int perPage,
        CancellationToken cancellationToken);
}