namespace AppKm.Athletes.Application.Queries.GetAthleteSettings;

public sealed record GetAthleteSettingsResult(
    Guid AthleteId,
    string DisplayName,
    string? ProfileImageUrl,
    string? CountryCode,
    DateOnly? BirthDate,
    string? PreferredSport,
    bool StravaConnected,
    string? StravaStatus,
    long? StravaAthleteId,
    DateTimeOffset? StravaConnectedAtUtc);