using AppKm.Athletes.Application.Interfaces;
using AppKm.Athletes.Application.Points;
using AppKm.Athletes.Domain.Aggregates.Athletes;
using Platform.SharedKernel.Errors;
using Platform.SharedKernel.Results;

namespace AppKm.Athletes.Application.Commands.ExpirePoints;

public sealed class ExpireCurrentAthletePointsCommandHandler
{
    private readonly IAthleteRepository _athleteRepository;
    private readonly PointExpirationService _expirationService;

    public ExpireCurrentAthletePointsCommandHandler(
        IAthleteRepository athleteRepository,
        PointExpirationService expirationService)
    {
        _athleteRepository = athleteRepository;
        _expirationService = expirationService;
    }

    public async Task<Result<ExpirePointsResult>> HandleAsync(
        Guid userId,
        CancellationToken cancellationToken)
    {
        Athlete? athlete =
            await _athleteRepository.GetByUserIdAsync(
                userId,
                cancellationToken);

        if (athlete is null)
        {
            return Result<ExpirePointsResult>.Failure(
                new Error(
                    "Athletes.Profile.NotFound",
                    "The athlete profile was not found."));
        }

        ExpirePointsResult result =
            await _expirationService.ExpireAsync(
                athlete.Id.Value,
                DateTimeOffset.UtcNow,
                cancellationToken);

        return Result<ExpirePointsResult>.Success(
            result);
    }
}