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
    private readonly IStravaTokenRevocationService _tokenRevocationService;

    public DisconnectStravaCommandHandler(
        IAthleteRepository athleteRepository,
        IStravaConnectionRepository stravaConnectionRepository,
        IAthleteUnitOfWork unitOfWork,
        IStravaTokenRevocationService tokenRevocationService)
    {
        _athleteRepository = athleteRepository;
        _stravaConnectionRepository = stravaConnectionRepository;
        _unitOfWork = unitOfWork;
        _tokenRevocationService = tokenRevocationService;
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

        try
        {
            await _tokenRevocationService.RevokeAsync(
                connection.RefreshTokenEncrypted,
                cancellationToken);
        }
        catch (HttpRequestException)
        {
            // La desconexión local no debe depender de que Strava
            // esté disponible en ese instante. Si la revocación remota
            // falla por red o por un error HTTP de Strava, App KM
            // revoca igualmente la conexión local.
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
