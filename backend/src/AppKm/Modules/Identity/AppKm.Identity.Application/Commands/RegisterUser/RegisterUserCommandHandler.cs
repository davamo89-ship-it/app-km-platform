using AppKm.Identity.Application.Interfaces;
using AppKm.Identity.Domain.Aggregates.Users;
using AppKm.Identity.Domain.ValueObjects;
using Platform.SharedKernel.Abstractions;
using Platform.SharedKernel.Results;
using AppKm.Identity.Domain.Aggregates.Roles;

namespace AppKm.Identity.Application.Commands.RegisterUser;

public sealed class RegisterUserCommandHandler
{
    private readonly IUserRepository _userRepository;
    private readonly IUserRoleRepository _userRoleRepository;
    private readonly IPasswordHasher _passwordHasher;
    private readonly IUnitOfWork _unitOfWork;
    private readonly IClock _clock;

        public RegisterUserCommandHandler(
            IUserRepository userRepository,
            IUserRoleRepository userRoleRepository,
            IPasswordHasher passwordHasher,
            IUnitOfWork unitOfWork,
            IClock clock)
        {
            _userRepository = userRepository;
            _userRoleRepository = userRoleRepository;
            _passwordHasher = passwordHasher;
            _unitOfWork = unitOfWork;
            _clock = clock;
        }

    public async Task<Result<UserId>> HandleAsync(
        RegisterUserCommand command,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(command);

        Result<Email> emailResult = Email.Create(command.Email);

        if (emailResult.IsFailure)
        {
            return Result<UserId>.Failure(emailResult.Error);
        }

        Result passwordPolicyResult =
            PasswordPolicy.Validate(command.Password);

        if (passwordPolicyResult.IsFailure)
        {
            return Result<UserId>.Failure(
                passwordPolicyResult.Error);
        }

        bool emailAlreadyExists =
            await _userRepository.ExistsByEmailAsync(
                emailResult.Value,
                cancellationToken);

        if (emailAlreadyExists)
        {
            return Result<UserId>.Failure(
                RegisterUserErrors.EmailAlreadyExists);
        }

        string hash = _passwordHasher.Hash(command.Password);

        Result<PasswordHash> passwordHashResult =
            PasswordHash.Create(hash);

        if (passwordHashResult.IsFailure)
        {
            return Result<UserId>.Failure(
                passwordHashResult.Error);
        }

        UserId userId = UserId.New();

        Result<User> userResult = User.Register(
            userId,
            emailResult.Value,
            passwordHashResult.Value,
            _clock.UtcNow);

        if (userResult.IsFailure)
        {
            return Result<UserId>.Failure(
                userResult.Error);
        }

        await _userRepository.AddAsync(
            userResult.Value,
            cancellationToken);

        UserRole athleteRole = UserRole.Create(
            userResult.Value.Id,
            RoleIds.Athlete,
            _clock.UtcNow);

        await _userRoleRepository.AddAsync(
            athleteRole,
            cancellationToken);

        await _unitOfWork.SaveChangesAsync(
            cancellationToken);

        return Result<UserId>.Success(userId);
    }
}