namespace AppKm.Identity.Api.Contracts;

public sealed record ConfirmPasswordResetRequest(
    string Email,
    string Code,
    string NewPassword);
