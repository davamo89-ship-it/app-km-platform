using AppKm.Identity.Domain.Aggregates.Users;
using AppKm.Identity.Domain.ValueObjects;

namespace AppKm.Identity.Application.Interfaces;

public interface IUserRepository
{
    Task<User?> GetByEmailAsync(
        Email email,
        CancellationToken cancellationToken);

    Task<bool> ExistsByEmailAsync(
        Email email,
        CancellationToken cancellationToken);

    Task AddAsync(
        User user,
        CancellationToken cancellationToken);
}