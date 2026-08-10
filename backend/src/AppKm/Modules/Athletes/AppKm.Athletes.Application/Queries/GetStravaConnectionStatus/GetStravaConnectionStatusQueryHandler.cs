using AppKm.Athletes.Application.Interfaces;
using AppKm.Athletes.Domain.Aggregates.Athletes;
using AppKm.Athletes.Domain.Aggregates.StravaConnections;

namespace AppKm.Athletes.Application.Queries.GetStravaConnectionStatus;

public sealed class GetStravaConnectionStatusQueryHandler
{
    private readonly IAthleteRepository _athleteRepository;
    private readonly IStravaConnectionRepository
        _stravaConnectionRepository;

    public GetStravaConnectionStatusQueryHandler(
        IAthleteRepository athleteRepository,
        IStravaConnectionRepository stravaConnectionRepository)
    {
        _athleteRepository = athleteRepository;
        _stravaConnectionRepository =
            stravaConnectionRepository;
    }

    public async Task<GetStravaConnectionStatusResult> HandleAsync(
        Guid userId,
        CancellationToken cancellationToken)
    {
        Athlete? athlete =
            await _athleteRepository.GetByUserIdAsync(
                userId,
                cancellationToken);

        if (athlete is null)
        {
            return new GetStravaConnectionStatusResult(
                false,
                null,
                null,
                null,
                null);
        }

        StravaConnection? connection =
            await _stravaConnectionRepository
                .GetByAthleteIdAsync(
                    athlete.Id.Value,
                    cancellationToken);

        if (connection is null ||
            connection.Status ==
            StravaConnectionStatus.Revoked)
        {
            return new GetStravaConnectionStatusResult(
                false,
                null,
                connection?.Status.ToString(),
                connection?.ConnectedAtUtc,
                null);
        }

        return new GetStravaConnectionStatusResult(
            true,
            connection.StravaAthleteId,
            connection.Status.ToString(),
            connection.ConnectedAtUtc,
            connection.AccessTokenExpiresAtUtc);
    }
}