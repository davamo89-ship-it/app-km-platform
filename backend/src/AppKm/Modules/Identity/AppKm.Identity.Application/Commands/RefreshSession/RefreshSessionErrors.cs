using Platform.SharedKernel.Errors;

namespace AppKm.Identity.Application.Commands.RefreshSession;

public static class RefreshSessionErrors
{
    public static readonly Error InvalidToken = new(
        "Identity.Refresh.InvalidToken",
        "The refresh token is invalid.");

    public static readonly Error InactiveSession = new(
        "Identity.Refresh.InactiveSession",
        "The session has expired or has been revoked.");

    public static readonly Error UserNotFound = new(
        "Identity.Refresh.UserNotFound",
        "The user associated with the session was not found.");

    public static readonly Error UserNotActive = new(
        "Identity.Refresh.UserNotActive",
        "The user account is not active.");
}