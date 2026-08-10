using Platform.SharedKernel.Errors;

namespace AppKm.Athletes.Application.Commands.DisconnectStrava;

public static class DisconnectStravaErrors
{
    public static readonly Error AthleteNotFound = new(
        "Athletes.Strava.AthleteNotFound",
        "The athlete profile was not found.");

    public static readonly Error ConnectionNotFound = new(
        "Athletes.Strava.ConnectionNotFound",
        "The Strava connection was not found.");
}