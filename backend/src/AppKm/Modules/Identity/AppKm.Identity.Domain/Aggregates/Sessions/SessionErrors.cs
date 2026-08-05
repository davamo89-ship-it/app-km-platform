using Platform.SharedKernel.Errors;

namespace AppKm.Identity.Domain.Aggregates.Sessions;

public static class SessionErrors
{
    public static readonly Error Inactive = new(
        "Identity.Session.Inactive",
        "The session is expired or has been revoked.");

    public static readonly Error InvalidExpiration = new(
        "Identity.Session.InvalidExpiration",
        "The session expiration is invalid.");
}