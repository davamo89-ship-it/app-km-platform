using AppKm.Athletes.Application.Interfaces;
using AppKm.Athletes.Domain.Aggregates.Athletes;
using Platform.SharedKernel.Results;

namespace AppKm.Athletes.Application.Queries.GetCurrentAthlete;

public sealed class GetCurrentAthleteQueryHandler
{
    private readonly IAthleteRepository _athleteRepository;

    public GetCurrentAthleteQueryHandler(
        IAthleteRepository athleteRepository)
    {
        _athleteRepository = athleteRepository;
    }

    public async Task<Result<GetCurrentAthleteResult>> HandleAsync(
        Guid userId,
        CancellationToken cancellationToken)
    {
        if (userId == Guid.Empty)
        {
            return Result<GetCurrentAthleteResult>.Failure(
                GetCurrentAthleteErrors.NotFound);
        }

        Athlete? athlete =
            await _athleteRepository.GetByUserIdAsync(
                userId,
                cancellationToken);

        if (athlete is null)
        {
            return Result<GetCurrentAthleteResult>.Failure(
                GetCurrentAthleteErrors.NotFound);
        }

        return Result<GetCurrentAthleteResult>.Success(
            new GetCurrentAthleteResult(
                athlete.Id.Value,
                athlete.UserId,
                athlete.DisplayName,
                athlete.Status,
                athlete.CreatedAtUtc,
                athlete.UpdatedAtUtc));
    }
}