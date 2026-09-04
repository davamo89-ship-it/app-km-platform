using AppKm.Identity.Application.Interfaces;
using AppKm.Identity.Domain.Aggregates.Roles;
using AppKm.Identity.Domain.Aggregates.Users;
using Microsoft.EntityFrameworkCore;

namespace AppKm.Identity.Infrastructure.Persistence.Repositories;

internal sealed class UserRoleRepository : IUserRoleRepository
{
    private readonly IdentityDbContext _dbContext;

    public UserRoleRepository(
        IdentityDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task AddAsync(
        UserRole userRole,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(userRole);

        await _dbContext.UserRoles.AddAsync(
            userRole,
            cancellationToken);
    }

    public Task<bool> ExistsAsync(
        UserId userId,
        RoleId roleId,
        CancellationToken cancellationToken)
    {
        return _dbContext.UserRoles.AnyAsync(
            userRole =>
                userRole.UserId == userId &&
                userRole.RoleId == roleId,
            cancellationToken);
    }

    public async Task<IReadOnlyCollection<string>>
        GetRoleNamesByUserIdAsync(
            UserId userId,
            CancellationToken cancellationToken)
    {
        return await (
            from userRole in _dbContext.UserRoles
            join role in _dbContext.Roles
                on userRole.RoleId equals role.Id
            where userRole.UserId == userId
            orderby role.Name
            select role.Name)
            .ToListAsync(cancellationToken);
    }

    public async Task<IReadOnlyCollection<Guid>>
        GetUserIdsByRoleNameAsync(
            string roleName,
            CancellationToken cancellationToken)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(roleName);

        string normalizedRoleName = roleName.Trim();

        List<UserId> userIds =
            await (
                from userRole in _dbContext.UserRoles
                join role in _dbContext.Roles
                    on userRole.RoleId equals role.Id
                where role.Name == normalizedRoleName
                select userRole.UserId)
            .Distinct()
            .ToListAsync(cancellationToken);

        return userIds
            .Select(userId => userId.Value)
            .ToList();
    }
}
