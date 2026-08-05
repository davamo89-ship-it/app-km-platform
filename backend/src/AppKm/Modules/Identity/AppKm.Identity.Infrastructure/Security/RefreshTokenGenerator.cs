using System.Security.Cryptography;
using System.Text;
using AppKm.Identity.Application.Interfaces;
using Microsoft.Extensions.Options;

namespace AppKm.Identity.Infrastructure.Security;

internal sealed class RefreshTokenGenerator
    : IRefreshTokenGenerator
{
    private readonly RefreshTokenOptions _options;

    public RefreshTokenGenerator(
        IOptions<RefreshTokenOptions> options)
    {
        _options = options.Value;
    }

    public RefreshTokenResult Generate()
    {
        byte[] randomBytes =
            RandomNumberGenerator.GetBytes(
                _options.SizeInBytes);

        string token =
            Convert.ToBase64String(randomBytes);

        string tokenHash = Hash(token);

        return new RefreshTokenResult(
            token,
            tokenHash);
    }

    public string Hash(string refreshToken)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(
            refreshToken);

        byte[] tokenBytes =
            Encoding.UTF8.GetBytes(refreshToken);

        byte[] hashBytes =
            SHA256.HashData(tokenBytes);

        return Convert.ToHexString(hashBytes);
    }
}