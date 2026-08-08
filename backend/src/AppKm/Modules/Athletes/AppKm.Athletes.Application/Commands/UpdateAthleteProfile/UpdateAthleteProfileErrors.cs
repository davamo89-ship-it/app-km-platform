using Platform.SharedKernel.Errors;

namespace AppKm.Athletes.Application.Commands.UpdateAthleteProfile;

public static class UpdateAthleteProfileErrors
{
    public static readonly Error NotFound = new(
        "Athletes.Profile.NotFound",
        "The athlete profile was not found.");

    public static readonly Error InvalidDisplayName = new(
        "Athletes.Profile.InvalidDisplayName",
        "The display name is invalid.");
}