using AppKm.Identity.Domain.Errors;
using Platform.SharedKernel.Results;
using Platform.SharedKernel.ValueObjects;

namespace AppKm.Identity.Domain.ValueObjects;

public sealed record PasswordHash : ValueObject
{
    private PasswordHash(string value)
    {
        Value = value;
    }

    public string Value { get; }

    public static Result<PasswordHash> Create(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
        {
            return Result<PasswordHash>.Failure(
                PasswordHashErrors.Required);
        }

        return Result<PasswordHash>.Success(
            new PasswordHash(value));
    }

    public override string ToString()
    {
        return Value;
    }
}