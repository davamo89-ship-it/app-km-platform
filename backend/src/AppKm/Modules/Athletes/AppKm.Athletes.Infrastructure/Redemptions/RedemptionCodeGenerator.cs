using System.Security.Cryptography;
using AppKm.Athletes.Application.Interfaces;

namespace AppKm.Athletes.Infrastructure.Redemptions;

internal sealed class RedemptionCodeGenerator
    : IRedemptionCodeGenerator
{
    public string Generate()
    {
        int value =
            RandomNumberGenerator.GetInt32(
                100000,
                1000000);

        return value.ToString("D6");
    }
}