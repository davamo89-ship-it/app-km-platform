namespace AppKm.Athletes.Api.Contracts;

public sealed record UpdateAthleteProfileRequest(
    string DisplayName,
    string? ProfileImageUrl,
    string? CountryCode,
    DateOnly? BirthDate,
    string? PreferredSport);