namespace AppKm.Athletes.Application.Commands.UpdateAthleteProfile;

public sealed record UpdateAthleteProfileResult(
    Guid AthleteId,
    Guid UserId,
    string DisplayName,
    DateTimeOffset UpdatedAtUtc);