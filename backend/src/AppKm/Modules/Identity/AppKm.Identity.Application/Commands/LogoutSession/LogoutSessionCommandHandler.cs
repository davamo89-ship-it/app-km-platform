using AppKm.Identity.Application.Interfaces;
using AppKm.Identity.Domain.Aggregates.Sessions;
using Platform.SharedKernel.Abstractions;
using Platform.SharedKernel.Results;

namespace AppKm.Identity.Application.Commands.LogoutSession;

public sealed class LogoutSessionCommandHandler
{
    private readonly ISessionRepository _sessionRepository;
    private readonly IRefreshTokenGenerator _refreshTokenGenerator;
    private readonly IUnitOfWork _unitOfWork;
    private readonly IClock _clock;

    public LogoutSessionCommandHandler(
        ISessionRepository sessionRepository,
        IRefreshTokenGenerator refreshTokenGenerator,
        IUnitOfWork unitOfWork,
        IClock clock)
    {
        _sessionRepository = sessionRepository;
        _refreshTokenGenerator = refreshTokenGenerator;
        _unitOfWork = unitOfWork;
        _clock = clock;
    }

    public async Task<Result> HandleAsync(
        LogoutSessionCommand command,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(command);

        if (string.IsNullOrWhiteSpace(command.RefreshToken))
        {
            return Result.Failure(
                LogoutSessionErrors.InvalidToken);
        }

        string refreshTokenHash =
            _refreshTokenGenerator.Hash(
                command.RefreshToken);

        Session? session =
            await _sessionRepository.GetByRefreshTokenHashAsync(
                refreshTokenHash,
                cancellationToken);

        if (session is null)
        {
            return Result.Failure(
                LogoutSessionErrors.InvalidToken);
        }

        session.Revoke(_clock.UtcNow);

        await _unitOfWork.SaveChangesAsync(
            cancellationToken);

        return Result.Success();
    }
}