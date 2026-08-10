using AppKm.Athletes.Application.Interfaces;
using Microsoft.AspNetCore.DataProtection;

namespace AppKm.Athletes.Infrastructure.Strava;

internal sealed class StravaTokenProtector
    : IStravaTokenProtector
{
    private readonly IDataProtector _protector;

    public StravaTokenProtector(
        IDataProtectionProvider dataProtectionProvider)
    {
        _protector =
            dataProtectionProvider.CreateProtector(
                "AppKm.Athletes.StravaTokens.v1");
    }

    public string Protect(string token)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(token);

        return _protector.Protect(token);
    }

    public string Unprotect(string protectedToken)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(
            protectedToken);

        return _protector.Unprotect(
            protectedToken);
    }
}