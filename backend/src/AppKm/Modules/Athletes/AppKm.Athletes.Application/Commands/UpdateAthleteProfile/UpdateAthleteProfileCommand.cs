namespace AppKm.Athletes.Application.Commands.UpdateAthleteProfile;

public sealed record UpdateAthleteProfileCommand(
    Guid UserId,
    string DisplayName,
    string? ProfileImageUrl,
    string? CountryCode,
    DateOnly? BirthDate,
    string? PreferredSport);