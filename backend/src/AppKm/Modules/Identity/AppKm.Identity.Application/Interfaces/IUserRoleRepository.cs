using AppKm.Identity.Domain.Aggregates.Roles;
using AppKm.Identity.Domain.Aggregates.Users;

namespace AppKm.Identity.Application.Interfaces;

public interface IUserRoleRepository
{
    Task AddAsync(
        UserRole userRole,
        CancellationToken cancellationToken);

    Task<bool> ExistsAsync(
        UserId userId,
        RoleId roleId,
        CancellationToken cancellationToken);

    Task<IReadOnlyCollection<string>> GetRoleNamesByUserIdAsync(
        UserId userId,
        CancellationToken cancellationToken);
}