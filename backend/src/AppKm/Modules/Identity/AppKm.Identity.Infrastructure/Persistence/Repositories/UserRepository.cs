using AppKm.Identity.Application.Interfaces;
using AppKm.Identity.Domain.Aggregates.Users;
using AppKm.Identity.Domain.ValueObjects;
using Microsoft.EntityFrameworkCore;
using EmailValue = AppKm.Identity.Domain.ValueObjects.Email;

namespace AppKm.Identity.Infrastructure.Persistence.Repositories;

internal sealed class UserRepository : IUserRepository
{
    private readonly IdentityDbContext _dbContext;

    public UserRepository(IdentityDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public Task<User?> GetByIdAsync(
        UserId userId,
        CancellationToken cancellationToken)
    {
        return _dbContext.Users.SingleOrDefaultAsync(
            user => user.Id == userId,
            cancellationToken);
    }

    public Task<User?> GetByEmailAsync(
        EmailValue email,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(email);

        return _dbContext.Users
            .SingleOrDefaultAsync(
                user => user.Email == email,
                cancellationToken);
    }

    public Task<bool> ExistsByEmailAsync(
        EmailValue email,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(email);

        return _dbContext.Users.AnyAsync(
            user => user.Email == email,
            cancellationToken);
    }

    public async Task AddAsync(
        User user,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(user);

        await _dbContext.Users.AddAsync(
            user,
            cancellationToken);
    }
}
