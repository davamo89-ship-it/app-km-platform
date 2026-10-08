using AppKm.Identity.Application.Commands.RegisterUser;
using AppKm.Identity.Application.Interfaces;
using AppKm.Identity.Domain.Aggregates.Sessions;
using AppKm.Identity.Domain.Aggregates.Users;
using AppKm.Identity.Domain.ValueObjects;
using Platform.SharedKernel.Abstractions;
using Platform.SharedKernel.Results;

namespace AppKm.Identity.Application.Commands.ConfirmPasswordReset;

public sealed class ConfirmPasswordResetCommandHandler
{
    private readonly IUserRepository _userRepository;
    private readonly ISessionRepository _sessionRepository;
    private readonly IPasswordHasher _passwordHasher;
    private readonly IPasswordResetCodeGenerator _codeGenerator;
    private readonly IUnitOfWork _unitOfWork;
    private readonly IClock _clock;

    public ConfirmPasswordResetCommandHandler(
        IUserRepository userRepository,
        ISessionRepository sessionRepository,
        IPasswordHasher passwordHasher,
        IPasswordResetCodeGenerator codeGenerator,
        IUnitOfWork unitOfWork,
        IClock clock)
    {
        _userRepository = userRepository;
        _sessionRepository = sessionRepository;
        _passwordHasher = passwordHasher;
        _codeGenerator = codeGenerator;
        _unitOfWork = unitOfWork;
        _clock = clock;
    }

    public async Task<Result> HandleAsync(
        ConfirmPasswordResetCommand command,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(command);

        Result passwordPolicyResult =
            PasswordPolicy.Validate(command.NewPassword);

        if (passwordPolicyResult.IsFailure)
        {
            return passwordPolicyResult;
        }

        var emailResult =
            Email.Create(command.Email);

        if (emailResult.IsFailure ||
            string.IsNullOrWhiteSpace(command.Code))
        {
            return Result.Failure(
                ConfirmPasswordResetErrors.InvalidOrExpiredCode);
        }

        User? user =
            await _userRepository.GetByEmailAsync(
                emailResult.Value,
                cancellationToken);

        DateTimeOffset utcNow =
            _clock.UtcNow;

        if (user is null ||
            user.Status != UserStatus.Active ||
            !user.HasUsablePasswordReset(utcNow) ||
            string.IsNullOrWhiteSpace(user.PasswordResetCodeHash) ||
            !_codeGenerator.Verify(
                command.Code,
                user.PasswordResetCodeHash))
        {
            return Result.Failure(
                ConfirmPasswordResetErrors.InvalidOrExpiredCode);
        }

        string hash =
            _passwordHasher.Hash(
                command.NewPassword);

        Result<PasswordHash> passwordHashResult =
            PasswordHash.Create(hash);

        if (passwordHashResult.IsFailure)
        {
            return Result.Failure(
                passwordHashResult.Error);
        }

        user.CompletePasswordReset(
            passwordHashResult.Value);

        IReadOnlyCollection<Session> activeSessions =
            await _sessionRepository.GetActiveByUserIdAsync(
                user.Id,
                utcNow,
                cancellationToken);

        foreach (Session session in activeSessions)
        {
            session.Revoke(utcNow);
        }

        await _unitOfWork.SaveChangesAsync(
            cancellationToken);

        return Result.Success();
    }
}
