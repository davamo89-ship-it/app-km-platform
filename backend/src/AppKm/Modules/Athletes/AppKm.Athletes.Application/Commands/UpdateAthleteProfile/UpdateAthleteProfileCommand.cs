namespace AppKm.Athletes.Application.Commands.UpdateAthleteProfile;

public sealed record UpdateAthleteProfileCommand(
    Guid UserId,
    string DisplayName);