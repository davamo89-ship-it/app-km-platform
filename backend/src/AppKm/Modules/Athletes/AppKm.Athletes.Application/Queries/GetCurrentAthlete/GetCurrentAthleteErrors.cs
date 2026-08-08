using Platform.SharedKernel.Errors;

namespace AppKm.Athletes.Application.Queries.GetCurrentAthlete;

public static class GetCurrentAthleteErrors
{
    public static readonly Error NotFound = new(
        "Athletes.Profile.NotFound",
        "The athlete profile was not found.");
}