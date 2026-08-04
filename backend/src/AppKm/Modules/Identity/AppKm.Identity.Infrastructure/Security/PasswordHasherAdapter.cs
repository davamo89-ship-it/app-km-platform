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

    public bool Verify(
        string passwordHash,
        string providedPassword)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(passwordHash);
        ArgumentException.ThrowIfNullOrWhiteSpace(providedPassword);

        PasswordVerificationResult result =
            _passwordHasher.VerifyHashedPassword(
                user: null!,
                hashedPassword: passwordHash,
                providedPassword: providedPassword);

        return result is
            PasswordVerificationResult.Success or
            PasswordVerificationResult.SuccessRehashNeeded;
    }
}