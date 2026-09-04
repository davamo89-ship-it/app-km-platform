using AppKm.Athletes.Application.Interfaces;
using AppKm.Athletes.Domain.Aggregates.Athletes;

namespace AppKm.Athletes.Application.Queries.GetAdminAthletes;

public sealed class GetAdminAthletesQueryHandler
{
    private readonly IAthleteRepository _athleteRepository;

    public GetAdminAthletesQueryHandler(
        IAthleteRepository athleteRepository)
    {
        _athleteRepository = athleteRepository;
    }

    public async Task<IReadOnlyList<GetAdminAthleteItem>> HandleAsync(
        CancellationToken cancellationToken)
    {
        IReadOnlyList<Athlete> athletes =
            await _athleteRepository.GetAllAsync(
                cancellationToken);

        return athletes
            .Select(athlete =>
                new GetAdminAthleteItem(
                    athlete.Id.Value,
                    athlete.UserId,
                    athlete.DisplayName,
                    athlete.ProfileImageUrl,
                    athlete.CountryCode,
                    athlete.BirthDate,
                    athlete.PreferredSport,
                    athlete.Status.ToString(),
                    athlete.CreatedAtUtc,
                    athlete.UpdatedAtUtc))
            .ToList();
    }
}
