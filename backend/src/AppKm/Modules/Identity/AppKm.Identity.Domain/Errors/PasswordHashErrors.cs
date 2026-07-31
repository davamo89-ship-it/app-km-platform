using Platform.SharedKernel.Errors;

namespace AppKm.Identity.Domain.Errors;

public static class PasswordHashErrors
{
    public static readonly Error Required = new(
        "Identity.PasswordHash.Required",
        "The password hash is required.");
}