namespace AppKm.Identity.Application.Interfaces;

public interface IPasswordResetCodeGenerator
{
    PasswordResetCode Generate();

    bool Verify(
        string code,
        string expectedHash);
}

public sealed record PasswordResetCode(
    string Code,
    string CodeHash);
