namespace AppKm.Athletes.Api.Contracts;

public sealed record UpdateAthleteProfileResponse(
    Guid AthleteId,
    Guid UserId,
    string DisplayName,
    DateTimeOffset UpdatedAtUtc);