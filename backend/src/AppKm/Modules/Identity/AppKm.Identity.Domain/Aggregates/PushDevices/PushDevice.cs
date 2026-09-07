using AppKm.Identity.Domain.Aggregates.Users;
using Platform.SharedKernel.Entities;

namespace AppKm.Identity.Domain.Aggregates.PushDevices;

public sealed class PushDevice : AggregateRoot<PushDeviceId>
{
    private const int MaxTokenLength = 4096;
    private const int MaxPlatformLength = 30;

    private PushDevice()
        : base(default)
    {
        Token = string.Empty;
        Platform = string.Empty;
    }

    private PushDevice(
        PushDeviceId id,
        UserId userId,
        string token,
        string platform,
        DateTimeOffset createdAtUtc,
        DateTimeOffset updatedAtUtc)
        : base(id)
    {
        UserId = userId;
        Token = token;
        Platform = platform;
        CreatedAtUtc = createdAtUtc;
        UpdatedAtUtc = updatedAtUtc;
        IsActive = true;
    }

    public UserId UserId { get; private set; }

    public string Token { get; private set; }

    public string Platform { get; private set; }

    public bool IsActive { get; private set; }

    public DateTimeOffset CreatedAtUtc { get; private set; }

    public DateTimeOffset UpdatedAtUtc { get; private set; }

    public static PushDevice Create(
        PushDeviceId id,
        UserId userId,
        string token,
        string platform,
        DateTimeOffset utcNow)
    {
        if (id.Value == Guid.Empty)
        {
            throw new ArgumentException(
                "The push device identifier cannot be empty.",
                nameof(id));
        }

        if (userId.Value == Guid.Empty)
        {
            throw new ArgumentException(
                "The user identifier cannot be empty.",
                nameof(userId));
        }

        string normalizedToken = NormalizeToken(token);
        string normalizedPlatform = NormalizePlatform(platform);

        return new PushDevice(
            id,
            userId,
            normalizedToken,
            normalizedPlatform,
            utcNow,
            utcNow);
    }

    public void RegisterForUser(
        UserId userId,
        string platform,
        DateTimeOffset utcNow)
    {
        if (userId.Value == Guid.Empty)
        {
            throw new ArgumentException(
                "The user identifier cannot be empty.",
                nameof(userId));
        }

        UserId = userId;
        Platform = NormalizePlatform(platform);
        IsActive = true;
        UpdatedAtUtc = utcNow;
    }

    public void Deactivate(DateTimeOffset utcNow)
    {
        IsActive = false;
        UpdatedAtUtc = utcNow;
    }

    private static string NormalizeToken(string token)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(token);

        string normalized = token.Trim();

        if (normalized.Length > MaxTokenLength)
        {
            throw new ArgumentOutOfRangeException(
                nameof(token),
                $"The push token cannot exceed {MaxTokenLength} characters.");
        }

        return normalized;
    }

    private static string NormalizePlatform(string platform)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(platform);

        string normalized = platform.Trim().ToLowerInvariant();

        if (normalized is not ("android" or "ios"))
        {
            throw new ArgumentOutOfRangeException(
                nameof(platform),
                platform,
                "The push platform must be android or ios.");
        }

        if (normalized.Length > MaxPlatformLength)
        {
            throw new ArgumentOutOfRangeException(
                nameof(platform),
                $"The push platform cannot exceed {MaxPlatformLength} characters.");
        }

        return normalized;
    }
}
