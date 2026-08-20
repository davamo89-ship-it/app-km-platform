using AppKm.Athletes.Domain.Aggregates.Athletes;

namespace AppKm.Athletes.Application.Queries.GetCurrentAthlete;

public sealed record GetCurrentAthleteResult(
    Guid AthleteId,
    Guid UserId,
    string DisplayName,
    string? ProfileImageUrl,
    string? CountryCode,
    DateOnly? BirthDate,
    string? PreferredSport,
    AthleteStatus Status,
    DateTimeOffset CreatedAtUtc,
    DateTimeOffset? UpdatedAtUtc);