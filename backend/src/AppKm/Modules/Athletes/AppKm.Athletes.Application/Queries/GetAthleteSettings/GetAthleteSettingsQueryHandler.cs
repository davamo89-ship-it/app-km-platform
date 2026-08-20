using AppKm.Athletes.Application.Interfaces;
using AppKm.Athletes.Domain.Aggregates.Athletes;
using AppKm.Athletes.Domain.Aggregates.StravaConnections;
using Platform.SharedKernel.Errors;
using Platform.SharedKernel.Results;

namespace AppKm.Athletes.Application.Queries.GetAthleteSettings;

public sealed class GetAthleteSettingsQueryHandler
{
    private readonly IAthleteRepository _athleteRepository;
    private readonly IStravaConnectionRepository _stravaConnectionRepository;

    public GetAthleteSettingsQueryHandler(
        IAthleteRepository athleteRepository,
        IStravaConnectionRepository stravaConnectionRepository)
    {
        _athleteRepository = athleteRepository;
        _stravaConnectionRepository = stravaConnectionRepository;
    }

    public async Task<Result<GetAthleteSettingsResult>> HandleAsync(
        Guid userId,
        CancellationToken cancellationToken)
    {
        Athlete? athlete =
            await _athleteRepository.GetByUserIdAsync(
                userId,
                cancellationToken);

        if (athlete is null)
        {
            return Result<GetAthleteSettingsResult>.Failure(
                new Error(
                    "Athletes.Profile.NotFound",
                    "The athlete profile was not found."));
        }

        StravaConnection? stravaConnection =
            await _stravaConnectionRepository.GetByAthleteIdAsync(
                athlete.Id.Value,
                cancellationToken);

        bool stravaConnected =
            stravaConnection is not null &&
            stravaConnection.Status ==
                StravaConnectionStatus.Active;

        return Result<GetAthleteSettingsResult>.Success(
            new GetAthleteSettingsResult(
                athlete.Id.Value,
                athlete.DisplayName,
                athlete.ProfileImageUrl,
                athlete.CountryCode,
                athlete.BirthDate,
                athlete.PreferredSport,
                stravaConnected,
                stravaConnection?.Status.ToString(),
                stravaConnection?.StravaAthleteId,
                stravaConnection?.ConnectedAtUtc));
    }
}