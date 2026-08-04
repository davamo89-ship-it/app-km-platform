using AppKm.Identity.Application.Interfaces;
using AppKm.Identity.Domain.Aggregates.Users;
using AppKm.Identity.Domain.ValueObjects;
using Platform.SharedKernel.Results;

namespace AppKm.Identity.Application.Commands.LoginUser;

public sealed class LoginUserCommandHandler
{
    private readonly IUserRepository _userRepository;
    private readonly IPasswordHasher _passwordHasher;
    private readonly IJwtTokenGenerator _jwtTokenGenerator;

    public LoginUserCommandHandler(
        IUserRepository userRepository,
        IPasswordHasher passwordHasher,
        IJwtTokenGenerator jwtTokenGenerator)
    {
        _userRepository = userRepository;
        _passwordHasher = passwordHasher;
        _jwtTokenGenerator = jwtTokenGenerator;
    }

    public async Task<Result<LoginUserResult>> HandleAsync(
        LoginUserCommand command,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(command);

        Result<Email> emailResult = Email.Create(command.Email);

        if (emailResult.IsFailure)
        {
            return Result<LoginUserResult>.Failure(
                LoginUserErrors.InvalidCredentials);
        }

        User? user = await _userRepository.GetByEmailAsync(
            emailResult.Value,
            cancellationToken);

        if (user is null)
        {
            return Result<LoginUserResult>.Failure(
                LoginUserErrors.InvalidCredentials);
        }

        bool passwordIsValid = _passwordHasher.Verify(
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

            JwtTokenResult tokenResult =
            _jwtTokenGenerator.Generate(
                user.Id,
                user.Email.Value);

        var loginResult = new LoginUserResult(
            user.Id,
            user.Email.Value,
            tokenResult.AccessToken,
            tokenResult.ExpiresAtUtc);

        return Result<LoginUserResult>.Success(loginResult);
        }
}