namespace AppKm.Identity.Infrastructure.Email;

public sealed class EmailOptions
{
    public const string SectionName = "Email";

    // Resend HTTPS API (used in staging/production).
    public string ApiKey { get; init; } = string.Empty;

    public string ApiBaseUrl { get; init; } = "https://api.resend.com";

    public string FromAddress { get; init; } = "onboarding@resend.dev";

    public string FromName { get; init; } = "App KM";

    // Legacy SMTP settings kept temporarily so the old sender source still
    // compiles while App KM transitions completely to the HTTPS provider.
    // They are no longer used by dependency injection.
    public string SmtpHost { get; init; } = string.Empty;

    public int SmtpPort { get; init; } = 587;

    public bool EnableSsl { get; init; } = true;

    public string Username { get; init; } = string.Empty;

    public string Password { get; init; } = string.Empty;
}
