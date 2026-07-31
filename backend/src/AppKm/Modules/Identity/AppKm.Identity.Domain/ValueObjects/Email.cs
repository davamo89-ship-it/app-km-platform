using System.Net.Mail;
using AppKm.Identity.Domain.Errors;
using Platform.SharedKernel.Results;

namespace AppKm.Identity.Domain.ValueObjects;

public sealed record Email
{
    private const int MaxLength = 254;

    private Email(string value)
    {
        Value = value;
    }

    public string Value { get; }

    public static Result<Email> Create(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return Result<Email>.Failure(EmailErrors.Required);
        }

        var normalizedValue = value.Trim().ToLowerInvariant();

        if (normalizedValue.Length > MaxLength)
        {
            return Result<Email>.Failure(EmailErrors.TooLong);
        }

        if (!IsValid(normalizedValue))
        {
            return Result<Email>.Failure(EmailErrors.InvalidFormat);
        }

        return Result<Email>.Success(new Email(normalizedValue));
    }

    public override string ToString()
    {
        return Value;
    }

    private static bool IsValid(string value)
    {
        try
        {
            var mailAddress = new MailAddress(value);

            return string.Equals(
                mailAddress.Address,
                value,
                StringComparison.OrdinalIgnoreCase);
        }
        catch (FormatException)
        {
            return false;
        }
    }
}