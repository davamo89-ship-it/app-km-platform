using Platform.SharedKernel.Errors;

namespace AppKm.Identity.Application.Commands.RegisterUser;

public static class RegisterUserErrors
{
    public static readonly Error EmailAlreadyExists = new(
        "Identity.Register.EmailAlreadyExists",
        "A user with this email address already exists.");

    public static readonly Error PasswordRequired = new(
        "Identity.Register.PasswordRequired",
        "The password is required.");

    public static readonly Error PasswordTooShort = new(
        "Identity.Register.PasswordTooShort",
        "The password must contain at least 8 characters.");

    public static readonly Error PasswordRequiresUppercase = new(
        "Identity.Register.PasswordRequiresUppercase",
        "The password must contain at least one uppercase letter.");

    public static readonly Error PasswordRequiresLowercase = new(
        "Identity.Register.PasswordRequiresLowercase",
        "The password must contain at least one lowercase letter.");

    public static readonly Error PasswordRequiresDigit = new(
        "Identity.Register.PasswordRequiresDigit",
        "The password must contain at least one number.");
}