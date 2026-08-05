using Platform.SharedKernel.Errors;

namespace AppKm.Identity.Application.Commands.LogoutSession;

public static class LogoutSessionErrors
{
    public static readonly Error InvalidToken = new(
        "Identity.Logout.InvalidToken",
        "The refresh token is invalid.");
}