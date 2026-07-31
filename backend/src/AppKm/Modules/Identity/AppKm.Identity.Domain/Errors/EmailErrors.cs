using Platform.SharedKernel.Errors;

namespace AppKm.Identity.Domain.Errors;

public static class EmailErrors
{
    public static readonly Error Required = new(
        "Identity.Email.Required",
        "The email address is required.");

    public static readonly Error TooLong = new(
        "Identity.Email.TooLong",
        "The email address cannot exceed 254 characters.");

    public static readonly Error InvalidFormat = new(
        "Identity.Email.InvalidFormat",
        "The email address format is invalid.");
}