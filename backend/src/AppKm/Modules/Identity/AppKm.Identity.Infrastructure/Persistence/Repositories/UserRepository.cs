using AppKm.Identity.Application.Interfaces;
using AppKm.Identity.Domain.Aggregates.Users;
using AppKm.Identity.Domain.ValueObjects;
using Microsoft.EntityFrameworkCore;

namespace AppKm.Identity.Infrastructure.Persistence.Repositories;

internal sealed class UserRepository : IUserRepository
{
    private readonly IdentityDbContext _dbContext;

    public UserRepository(IdentityDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public Task<User?> GetByEmailAsync(
        Email email,
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(email);

        return _dbContext.Users
            .SingleOrDefaultAsync(
                user => user.Email == email,
                cancellationToken);
    }

    public Task<bool> ExistsByEmailAsync(
        Email email,
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