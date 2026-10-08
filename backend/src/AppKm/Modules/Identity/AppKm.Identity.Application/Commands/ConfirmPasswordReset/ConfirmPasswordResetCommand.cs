namespace AppKm.Identity.Application.Commands.ConfirmPasswordReset;

public sealed record ConfirmPasswordResetCommand(
    string Email,
    string Code,
    string NewPassword);
