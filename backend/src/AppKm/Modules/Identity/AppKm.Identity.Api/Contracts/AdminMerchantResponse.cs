namespace AppKm.Identity.Api.Contracts;

public sealed record AdminMerchantResponse(
    Guid AthleteId,
    Guid UserId,
    string DisplayName,
    string? ProfileImageUrl,
    string? CountryCode,
    string? PreferredSport,
    string Status,
    DateTimeOffset CreatedAtUtc,
    DateTimeOffset? UpdatedAtUtc);
