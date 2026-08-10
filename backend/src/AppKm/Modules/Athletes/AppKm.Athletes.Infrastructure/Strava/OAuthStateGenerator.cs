using System.Security.Cryptography;
using AppKm.Athletes.Application.Interfaces;
using Microsoft.AspNetCore.WebUtilities;

namespace AppKm.Athletes.Infrastructure.Strava;

internal sealed class OAuthStateGenerator
    : IOAuthStateGenerator
{
    public string Generate()
    {
        byte[] bytes =
            RandomNumberGenerator.GetBytes(32);

        return WebEncoders.Base64UrlEncode(bytes);
    }
}