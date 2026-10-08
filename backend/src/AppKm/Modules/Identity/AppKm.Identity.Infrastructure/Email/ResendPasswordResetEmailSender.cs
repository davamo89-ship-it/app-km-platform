using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using AppKm.Identity.Application.Interfaces;
using Microsoft.Extensions.Options;

namespace AppKm.Identity.Infrastructure.Email;

internal sealed class ResendPasswordResetEmailSender
    : IPasswordResetEmailSender
{
    private static readonly HttpClient HttpClient = new()
    {
        Timeout = TimeSpan.FromSeconds(15)
    };

    private readonly EmailOptions _options;

    public ResendPasswordResetEmailSender(
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

        var endpoint =
            $"{_options.ApiBaseUrl.TrimEnd('/')}/emails";

        using var request =
            new HttpRequestMessage(
                HttpMethod.Post,
                endpoint);

        request.Headers.Authorization =
            new AuthenticationHeaderValue(
                "Bearer",
                _options.ApiKey);

        string sender =
            string.IsNullOrWhiteSpace(_options.FromName)
                ? _options.FromAddress
                : $"{_options.FromName} <{_options.FromAddress}>";

        var payload = new
        {
            from = sender,
            to = new[] { email },
            subject = "Código para recuperar tu contraseña de App KM",
            text =
                $"Tu código para recuperar la contraseña de App KM es: {code}\r\n\r\n" +
                "El código vence en 15 minutos.\r\n\r\n" +
                "Si no solicitaste este cambio, puedes ignorar este correo."
        };

        request.Content = JsonContent.Create(payload);

        using HttpResponseMessage response =
            await HttpClient.SendAsync(
                request,
                HttpCompletionOption.ResponseHeadersRead,
                cancellationToken);

        if (response.IsSuccessStatusCode)
        {
            return;
        }

        string responseBody =
            await response.Content.ReadAsStringAsync(
                cancellationToken);

        string safeDetails = GetSafeErrorDetails(responseBody);

        throw new InvalidOperationException(
            $"Resend email delivery failed with HTTP " +
            $"{(int)response.StatusCode} ({response.ReasonPhrase}). " +
            safeDetails);
    }

    private void ValidateConfiguration()
    {
        if (string.IsNullOrWhiteSpace(_options.ApiKey))
        {
            throw new InvalidOperationException(
                "Email:ApiKey is required.");
        }

        if (!Uri.TryCreate(
                _options.ApiBaseUrl,
                UriKind.Absolute,
                out Uri? apiBaseUri) ||
            apiBaseUri.Scheme != Uri.UriSchemeHttps)
        {
            throw new InvalidOperationException(
                "Email:ApiBaseUrl must be a valid HTTPS URL.");
        }

        if (string.IsNullOrWhiteSpace(
                _options.FromAddress))
        {
            throw new InvalidOperationException(
                "Email:FromAddress is required.");
        }
    }

    private static string GetSafeErrorDetails(
        string responseBody)
    {
        if (string.IsNullOrWhiteSpace(responseBody))
        {
            return "Resend returned an empty error response.";
        }

        try
        {
            using JsonDocument document =
                JsonDocument.Parse(responseBody);

            JsonElement root = document.RootElement;

            string? name =
                root.TryGetProperty("name", out JsonElement nameElement)
                    ? nameElement.GetString()
                    : null;

            string? message =
                root.TryGetProperty("message", out JsonElement messageElement)
                    ? messageElement.GetString()
                    : null;

            if (!string.IsNullOrWhiteSpace(name) &&
                !string.IsNullOrWhiteSpace(message))
            {
                return $"Resend error: {name}: {message}";
            }

            if (!string.IsNullOrWhiteSpace(message))
            {
                return $"Resend error: {message}";
            }
        }
        catch (JsonException)
        {
            // Do not include arbitrary provider responses in logs.
        }

        return "Resend returned an error response.";
    }
}
