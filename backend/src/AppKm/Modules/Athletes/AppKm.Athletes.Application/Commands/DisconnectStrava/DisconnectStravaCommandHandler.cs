using AppKm.Athletes.Application.Interfaces;
using AppKm.Athletes.Domain.Aggregates.Athletes;
using AppKm.Athletes.Domain.Aggregates.StravaConnections;
using Platform.SharedKernel.Results;

namespace AppKm.Athletes.Application.Commands.DisconnectStrava;

public sealed class DisconnectStravaCommandHandler
{
    private readonly IAthleteRepository _athleteRepository;
    private readonly IStravaConnectionRepository _stravaConnectionRepository;
    private readonly IAthleteUnitOfWork _unitOfWork;

    public DisconnectStravaCommandHandler(
        IAthleteRepository athleteRepository,
        IStravaConnectionRepository stravaConnectionRepository,
        IAthleteUnitOfWork unitOfWork)
    {
        _athleteRepository = athleteRepository;
        _stravaConnectionRepository = stravaConnectionRepository;
        _unitOfWork = unitOfWork;
    }

    public async Task<Result<DisconnectStravaResult>> HandleAsync(
        DisconnectStravaCommand command,
        CancellationToken cancellationToken)
    {
        Athlete? athlete =
            await _athleteRepository.GetByUserIdAsync(
                command.UserId,
                cancellationToken);

        if (athlete is null)
        {
            return Result<DisconnectStravaResult>.Failure(
                DisconnectStravaErrors.AthleteNotFound);
        }

        StravaConnection? connection =
            await _stravaConnectionRepository.GetByAthleteIdAsync(
                athlete.Id.Value,
                cancellationToken);

        if (connection is null)
        {
            return Result<DisconnectStravaResult>.Failure(
                DisconnectStravaErrors.ConnectionNotFound);
        }

        DateTimeOffset disconnectedAtUtc =
            DateTimeOffset.UtcNow;

        connection.Revoke(
            disconnectedAtUtc);

        await _unitOfWork.SaveChangesAsync(
            cancellationToken);

        return Result<DisconnectStravaResult>.Success(
            new DisconnectStravaResult(
                athlete.Id.Value,
                connection.Status.ToString(),
                disconnectedAtUtc));
    }
}