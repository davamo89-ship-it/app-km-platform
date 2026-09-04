namespace AppKm.Athletes.Application.Queries.GetAdminAthletes;

public sealed record GetAdminAthleteItem(
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
