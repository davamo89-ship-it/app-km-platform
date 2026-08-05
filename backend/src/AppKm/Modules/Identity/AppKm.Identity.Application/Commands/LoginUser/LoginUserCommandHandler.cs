using AppKm.Identity.Application.Interfaces;
using AppKm.Identity.Domain.Aggregates.Sessions;
using AppKm.Identity.Domain.Aggregates.Users;
using AppKm.Identity.Domain.ValueObjects;
using Platform.SharedKernel.Abstractions;
using Platform.SharedKernel.Results;

namespace AppKm.Identity.Application.Commands.LoginUser;

public sealed class LoginUserCommandHandler
{
    private const int RefreshTokenExpirationDays = 30;

    private readonly IUserRepository _userRepository;
    private readonly ISessionRepository _sessionRepository;
    private readonly IPasswordHasher _passwordHasher;
    private readonly IJwtTokenGenerator _jwtTokenGenerator;
    private readonly IRefreshTokenGenerator _refreshTokenGenerator;
    private readonly IUnitOfWork _unitOfWork;
    private readonly IClock _clock;

    public LoginUserCommandHandler(
        IUserRepository userRepository,
        ISessionRepository sessionRepository,
        IPasswordHasher passwordHasher,
        IJwtTokenGenerator jwtTokenGenerator,
        IRefreshTokenGenerator refreshTokenGenerator,
        IUnitOfWork unitOfWork,
        IClock clock)
    {
        _userRepository = userRepository;
        _sessionRepository = sessionRepository;
        _passwordHasher = passwordHasher;
        _jwtTokenGenerator = jwtTokenGenerator;
        _refreshTokenGenerator = refreshTokenGenerator;
        _unitOfWork = unitOfWork;
        _clock = clock;
    }

    public async Task<Result<LoginUserResult>> HandleAsync(
        LoginUserCommand command,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(command);

        Result<Email> emailResult =
            Email.Create(command.Email);

        if (emailResult.IsFailure)
        {
            return Result<LoginUserResult>.Failure(
                LoginUserErrors.InvalidCredentials);
        }

        User? user =
            await _userRepository.GetByEmailAsync(
                emailResult.Value,
                cancellationToken);

        if (user is null)
        {
            return Result<LoginUserResult>.Failure(
                LoginUserErrors.InvalidCredentials);
        }

        bool passwordIsValid =
            _passwordHasher.Verify(
                user.PasswordHash.Value,
                command.Password);

        if (!passwordIsValid)
        {
            return Result<LoginUserResult>.Failure(
                LoginUserErrors.InvalidCredentials);
        }

        if (user.Status != UserStatus.Active)
        {
            return Result<LoginUserResult>.Failure(
                LoginUserErrors.AccountNotActive);
        }

        DateTimeOffset utcNow = _clock.UtcNow;

        JwtTokenResult accessTokenResult =
            _jwtTokenGenerator.Generate(
                user.Id,
                user.Email.Value);

        RefreshTokenResult refreshTokenResult =
            _refreshTokenGenerator.Generate();

        DateTimeOffset refreshTokenExpiresAtUtc =
            utcNow.AddDays(
                RefreshTokenExpirationDays);

        Result<Session> sessionResult =
            Session.Create(
                SessionId.New(),
                user.Id,
                refreshTokenResult.TokenHash,
                utcNow,
                refreshTokenExpiresAtUtc);

        if (sessionResult.IsFailure)
        {
            return Result<LoginUserResult>.Failure(
                sessionResult.Error);
        }

        await _sessionRepository.AddAsync(
            sessionResult.Value,
            cancellationToken);

        await _unitOfWork.SaveChangesAsync(
            cancellationToken);

        var loginResult = new LoginUserResult(
            user.Id,
            user.Email.Value,
            accessTokenResult.AccessToken,
            accessTokenResult.ExpiresAtUtc,
            refreshTokenResult.Token,
            refreshTokenExpiresAtUtc);

        return Result<LoginUserResult>.Success(
            loginResult);
    }
}