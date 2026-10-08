using System.Net;
using System.Net.Mail;
using AppKm.Identity.Application.Interfaces;
using Microsoft.Extensions.Options;

namespace AppKm.Identity.Infrastructure.Email;

internal sealed class SmtpPasswordResetEmailSender
    : IPasswordResetEmailSender
{
    private readonly EmailOptions _options;

    public SmtpPasswordResetEmailSender(
        IOptions<EmailOptions> options)
    {
        _options = options.Value;
    }

    public async Task SendCodeAsync(
        string email,
        string code,
        DateTimeOffset expiresAtUtc,
        CancellationToken cancellationToken)
    {
        ValidateConfiguration();

        using var message =
            new MailMessage
            {
                From = new MailAddress(
                    _options.FromAddress,
                    _options.FromName),
                Subject =
                    "Código para recuperar tu contraseña de App KM",
                Body =
                    $"Tu código para recuperar la contraseña de App KM es: {code}\r\n\r\n" +
                    "El código vence en 15 minutos.\r\n\r\n" +
                    "Si no solicitaste este cambio, puedes ignorar este correo.",
                IsBodyHtml = false
            };

        message.To.Add(
            new MailAddress(email));

        using var client =
            new SmtpClient(
                _options.SmtpHost,
                _options.SmtpPort)
            {
                EnableSsl =
                    _options.EnableSsl,
                DeliveryMethod =
                    SmtpDeliveryMethod.Network,
                UseDefaultCredentials =
                    false
            };

        if (!string.IsNullOrWhiteSpace(
                _options.Username))
        {
            client.Credentials =
                new NetworkCredential(
                    _options.Username,
                    _options.Password);
        }

        cancellationToken.ThrowIfCancellationRequested();

        await client
            .SendMailAsync(message)
            .WaitAsync(cancellationToken);
    }

    private void ValidateConfiguration()
    {
        if (string.IsNullOrWhiteSpace(
                _options.SmtpHost))
        {
            throw new InvalidOperationException(
                "Email:SmtpHost is required.");
        }

        if (_options.SmtpPort <= 0 ||
            _options.SmtpPort > 65535)
        {
            throw new InvalidOperationException(
                "Email:SmtpPort is invalid.");
        }

        if (string.IsNullOrWhiteSpace(
                _options.FromAddress))
        {
            throw new InvalidOperationException(
                "Email:FromAddress is required.");
        }
    }
}
