namespace AppKm.Athletes.Api.Contracts;

public sealed record CurrentAthleteResponse(
    Guid AthleteId,
    Guid UserId,
    string DisplayName,
    string Status,
    DateTimeOffset CreatedAtUtc,
    DateTimeOffset? UpdatedAtUtc);