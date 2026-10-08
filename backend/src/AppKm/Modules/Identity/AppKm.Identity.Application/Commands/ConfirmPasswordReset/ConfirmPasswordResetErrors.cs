using Platform.SharedKernel.Errors;

namespace AppKm.Identity.Application.Commands.ConfirmPasswordReset;

public static class ConfirmPasswordResetErrors
{
    public static readonly Error InvalidOrExpiredCode = new(
        "Identity.PasswordReset.InvalidOrExpiredCode",
        "The password reset code is invalid or has expired.");
}
