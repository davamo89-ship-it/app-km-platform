namespace AppKm.Identity.Application.Interfaces;

public interface IPasswordResetEmailSender
{
    Task SendCodeAsync(
        string email,
        string code,
        DateTimeOffset expiresAtUtc,
        CancellationToken cancellationToken);
}
