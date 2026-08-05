namespace AppKm.Identity.Infrastructure.Security;

public sealed class RefreshTokenOptions
{
    public const string SectionName = "RefreshToken";

    public int ExpirationDays { get; init; } = 30;

    public int SizeInBytes { get; init; } = 64;
}