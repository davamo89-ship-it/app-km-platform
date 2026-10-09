using System.Security.Cryptography;
using AppKm.Identity.Application.Interfaces;
using AppKm.Identity.Domain.Aggregates.Roles;
using AppKm.Identity.Domain.Aggregates.Users;
using AppKm.Identity.Domain.ValueObjects;
using Platform.SharedKernel.Abstractions;
using Platform.SharedKernel.Results;

namespace AppKm.Identity.Application.Commands.ProvisionCognitoUser;

public sealed class ProvisionCognitoUserCommandHandler
{
    private readonly IUserRepository _userRepository;
    private readonly IUserRoleRepository _userRoleRepository;
    private readonly IPasswordHasher _passwordHasher;
    private readonly IUnitOfWork _unitOfWork;
    private readonly IClock _clock;
    private readonly IAthleteProfileProvisioner _athleteProfileProvisioner;

    public ProvisionCognitoUserCommandHandler(
        IUserRepository userRepository,
        IUserRoleRepository userRoleRepository,
        IPasswordHasher passwordHasher,
        IUnitOfWork unitOfWork,
        IClock clock,
        IAthleteProfileProvisioner athleteProfileProvisioner)
    {
        _userRepository = userRepository;
        _userRoleRepository = userRoleRepository;
        _passwordHasher = passwordHasher;
        _unitOfWork = unitOfWork;
        _clock = clock;
        _athleteProfileProvisioner = athleteProfileProvisioner;
    }

    public async Task<Result<ProvisionCognitoUserResult>> HandleAsync(
        ProvisionCognitoUserCommand command,
        CancellationToken cancellationToken)
    {
        if (command.UserId == Guid.Empty)
        {
            return Result<ProvisionCognitoUserResult>.Failure(
                ProvisionCognitoUserErrors.InvalidUser);
        }

        Result<Email> emailResult = Email.Create(command.Email);
        if (emailResult.IsFailure)
        {
            return Result<ProvisionCognitoUserResult>.Failure(emailResult.Error);
        }

        UserId userId = UserId.From(command.UserId);
        User? user = await _userRepository.GetByIdAsync(userId, cancellationToken);

        if (user is null)
        {
            User? byEmail = await _userRepository.GetByEmailAsync(
                emailResult.Value,
                cancellationToken);

            if (byEmail is not null)
            {
                return Result<ProvisionCognitoUserResult>.Failure(
                    ProvisionCognitoUserErrors.EmailAlreadyUsed);
            }

            string unreachablePassword = Convert.ToBase64String(
                RandomNumberGenerator.GetBytes(64));
            string hash = _passwordHasher.Hash(unreachablePassword);
            Result<PasswordHash> passwordHashResult = PasswordHash.Create(hash);

            if (passwordHashResult.IsFailure)
            {
                return Result<ProvisionCognitoUserResult>.Failure(
                    passwordHashResult.Error);
            }

            Result<User> userResult = User.Register(
                userId,
                emailResult.Value,
                passwordHashResult.Value,
                _clock.UtcNow);

            if (userResult.IsFailure)
            {
                return Result<ProvisionCognitoUserResult>.Failure(userResult.Error);
            }

            userResult.Value.Activate();
            user = userResult.Value;
            await _userRepository.AddAsync(user, cancellationToken);
        }

        IReadOnlyCollection<string> normalizedRoles = NormalizeRoles(command.Roles);

        foreach ((RoleId roleId, string roleName) in ResolveRoles(normalizedRoles))
        {
            bool exists = await _userRoleRepository.ExistsAsync(
                userId,
                roleId,
                cancellationToken);

            if (!exists)
            {
                await _userRoleRepository.AddAsync(
                    UserRole.Create(userId, roleId, _clock.UtcNow),
                    cancellationToken);
            }
        }

        await _unitOfWork.SaveChangesAsync(cancellationToken);

        await _athleteProfileProvisioner.CreateAsync(
            command.UserId,
            command.Email.Split('@')[0],
            cancellationToken);

        IReadOnlyCollection<string> storedRoles =
            await _userRoleRepository.GetRoleNamesByUserIdAsync(
                userId,
                cancellationToken);

        return Result<ProvisionCognitoUserResult>.Success(
            new ProvisionCognitoUserResult(
                command.UserId,
                emailResult.Value.Value,
                storedRoles));
    }

    private static IReadOnlyCollection<string> NormalizeRoles(
        IReadOnlyCollection<string> roles)
    {
        string[] normalized = roles
            .Where(RoleNames.IsValid)
            .Distinct(StringComparer.Ordinal)
            .ToArray();

        return normalized.Length == 0
            ? new[] { RoleNames.Athlete }
            : normalized;
    }

    private static IEnumerable<(RoleId Id, string Name)> ResolveRoles(
        IReadOnlyCollection<string> roles)
    {
        foreach (string role in roles)
        {
            if (role == RoleNames.Athlete)
            {
                yield return (RoleIds.Athlete, RoleNames.Athlete);
            }
            else if (role == RoleNames.Merchant)
            {
                yield return (RoleIds.Merchant, RoleNames.Merchant);
            }
            else if (role == RoleNames.Admin)
            {
                yield return (RoleIds.Admin, RoleNames.Admin);
            }
        }
    }
}
