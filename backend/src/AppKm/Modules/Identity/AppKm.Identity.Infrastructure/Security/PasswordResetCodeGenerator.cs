using System.Security.Cryptography;
using System.Text;
using AppKm.Identity.Application.Interfaces;

namespace AppKm.Identity.Infrastructure.Security;

internal sealed class PasswordResetCodeGenerator
    : IPasswordResetCodeGenerator
{
    public PasswordResetCode Generate()
    {
        int value =
            RandomNumberGenerator.GetInt32(
                0,
                1_000_000);

        string code =
            value.ToString("D6");

        return new PasswordResetCode(
            code,
            Hash(code));
    }

    public bool Verify(
        string code,
        string expectedHash)
    {
        if (string.IsNullOrWhiteSpace(code) ||
            string.IsNullOrWhiteSpace(expectedHash))
        {
            return false;
        }

        byte[] providedHash =
            SHA256.HashData(
                Encoding.UTF8.GetBytes(
                    code.Trim()));

        byte[] expectedBytes;

        try
        {
            expectedBytes =
                Convert.FromHexString(
                    expectedHash.Trim());
        }
        catch (FormatException)
        {
            return false;
        }

        return expectedBytes.Length == providedHash.Length &&
            CryptographicOperations.FixedTimeEquals(
                providedHash,
                expectedBytes);
    }

    private static string Hash(string code)
    {
        byte[] hash =
            SHA256.HashData(
                Encoding.UTF8.GetBytes(code));

        return Convert.ToHexString(hash);
    }
}
