using AppKm.Athletes.Application.Interfaces;
using AppKm.Athletes.Domain.Aggregates.Athletes;
using AppKm.Athletes.Domain.Aggregates.StravaConnections;
using Platform.SharedKernel.Errors;
using Platform.SharedKernel.Results;

namespace AppKm.Athletes.Application.Queries.GetStravaActivities;

public sealed class GetStravaActivitiesQueryHandler
{
    private readonly IAthleteRepository _athleteRepository;
    private readonly IStravaConnectionRepository _connectionRepository;
    private readonly IStravaAccessTokenService _accessTokenService;
    private readonly IStravaActivitiesClient _activitiesClient;

    public GetStravaActivitiesQueryHandler(
        IAthleteRepository athleteRepository,
        IStravaConnectionRepository connectionRepository,
        IStravaAccessTokenService accessTokenService,
        IStravaActivitiesClient activitiesClient)
    {
        _athleteRepository = athleteRepository;
        _connectionRepository = connectionRepository;
        _accessTokenService = accessTokenService;
        _activitiesClient = activitiesClient;
    }

    public async Task<Result<IReadOnlyList<StravaActivityResult>>> HandleAsync(
        GetStravaActivitiesQuery query,
        CancellationToken cancellationToken)
    {
        Athlete? athlete =
            await _athleteRepository.GetByUserIdAsync(
                query.UserId,
                cancellationToken);

        if (athlete is null)
        {
            return Result<IReadOnlyList<StravaActivityResult>>.Failure(
                new Error(
                    "Athletes.Profile.NotFound",
                    "The athlete profile was not found."));
        }

        StravaConnection? connection =
            await _connectionRepository.GetByAthleteIdAsync(
                athlete.Id.Value,
                cancellationToken);

        if (connection is null ||
            connection.Status != StravaConnectionStatus.Active)
        {
            return Result<IReadOnlyList<StravaActivityResult>>.Failure(
                new Error(
                    "Athletes.Strava.NotConnected",
                    "The athlete does not have an active Strava connection."));
        }

        string accessToken =
            await _accessTokenService.GetValidAccessTokenAsync(
                connection,
                cancellationToken);

        IReadOnlyList<StravaActivityResult> activities =
            await _activitiesClient.GetActivitiesAsync(
                accessToken,
                query.After,
                query.Before,
                query.Page,
                query.PerPage,
                cancellationToken);

        return Result<IReadOnlyList<StravaActivityResult>>.Success(
            activities);
    }
}