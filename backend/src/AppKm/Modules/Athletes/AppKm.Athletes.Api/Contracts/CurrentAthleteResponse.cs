namespace AppKm.Athletes.Api.Contracts;

public sealed record CurrentAthleteResponse(
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