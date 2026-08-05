using AppKm.Identity.Application.Interfaces;
using AppKm.Identity.Domain.Aggregates.Sessions;
using AppKm.Identity.Domain.Aggregates.Users;
using Platform.SharedKernel.Abstractions;
using Platform.SharedKernel.Results;

namespace AppKm.Identity.Application.Commands.RefreshSession;

public sealed class RefreshSessionCommandHandler
{
    private const int RefreshTokenExpirationDays = 30;

    private readonly ISessionRepository _sessionRepository;
    private readonly IUserRepository _userRepository;
    private readonly IRefreshTokenGenerator _refreshTokenGenerator;
    private readonly IJwtTokenGenerator _jwtTokenGenerator;
    private readonly IUnitOfWork _unitOfWork;
    private readonly IClock _clock;

    public RefreshSessionCommandHandler(
        ISessionRepository sessionRepository,
        IUserRepository userRepository,
        IRefreshTokenGenerator refreshTokenGenerator,
        IJwtTokenGenerator jwtTokenGenerator,
        IUnitOfWork unitOfWork,
        IClock clock)
    {
        _sessionRepository = sessionRepository;
        _userRepository = userRepository;
        _refreshTokenGenerator = refreshTokenGenerator;
        _jwtTokenGenerator = jwtTokenGenerator;
        _unitOfWork = unitOfWork;
        _clock = clock;
    }

    public async Task<Result<RefreshSessionResult>> HandleAsync(
        RefreshSessionCommand command,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(command);

        if (string.IsNullOrWhiteSpace(command.RefreshToken))
        {
            return Result<RefreshSessionResult>.Failure(
                RefreshSessionErrors.InvalidToken);
        }

        string currentTokenHash =
            _refreshTokenGenerator.Hash(
                command.RefreshToken);

        Session? session =
            await _sessionRepository.GetByRefreshTokenHashAsync(
                currentTokenHash,
                cancellationToken);

        if (session is null)
        {
            return Result<RefreshSessionResult>.Failure(
                RefreshSessionErrors.InvalidToken);
        }

        DateTimeOffset utcNow = _clock.UtcNow;

        if (!session.IsActive(utcNow))
        {
            return Result<RefreshSessionResult>.Failure(
                RefreshSessionErrors.InactiveSession);
        }

        User? user =
            await _userRepository.GetByIdAsync(
                session.UserId,
                cancellationToken);

        if (user is null)
        {
            return Result<RefreshSessionResult>.Failure(
                RefreshSessionErrors.UserNotFound);
        }

        if (user.Status != UserStatus.Active)
        {
            return Result<RefreshSessionResult>.Failure(
                RefreshSessionErrors.UserNotActive);
        }

        RefreshTokenResult newRefreshToken =
            _refreshTokenGenerator.Generate();

        DateTimeOffset newRefreshExpiration =
            utcNow.AddDays(RefreshTokenExpirationDays);

        Result rotationResult =
            session.RotateRefreshToken(
                newRefreshToken.TokenHash,
                newRefreshExpiration,
                utcNow);

        if (rotationResult.IsFailure)
        {
            return Result<RefreshSessionResult>.Failure(
                rotationResult.Error);
        }

        JwtTokenResult newAccessToken =
            _jwtTokenGenerator.Generate(
                user.Id,
                user.Email.Value);

        await _unitOfWork.SaveChangesAsync(
            cancellationToken);

        return Result<RefreshSessionResult>.Success(
            new RefreshSessionResult(
                user.Id.Value,
                user.Email.Value,
                newAccessToken.AccessToken,
                newAccessToken.ExpiresAtUtc,
                newRefreshToken.Token,
                newRefreshExpiration));
    }
}