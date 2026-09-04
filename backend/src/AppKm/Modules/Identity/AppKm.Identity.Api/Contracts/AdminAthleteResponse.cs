namespace AppKm.Identity.Api.Contracts;

public sealed record AdminAthleteResponse(
    Guid AthleteId,
    Guid UserId,
    string DisplayName,
    string? ProfileImageUrl,
    string? CountryCode,
    DateOnly? BirthDate,
    string? PreferredSport,
    string Status,
    DateTimeOffset CreatedAtUtc,
    DateTimeOffset? UpdatedAtUtc);
