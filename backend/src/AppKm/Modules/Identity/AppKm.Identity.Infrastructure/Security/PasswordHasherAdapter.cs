using AppKm.Identity.Application.Interfaces;
using Microsoft.AspNetCore.Identity;

namespace AppKm.Identity.Infrastructure.Security;

internal sealed class PasswordHasherAdapter : IPasswordHasher
{
    private readonly PasswordHasher<object> _passwordHasher = new();

    public string Hash(string password)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(password);

        return _passwordHasher.HashPassword(
            user: null!,
            password);
    }
}