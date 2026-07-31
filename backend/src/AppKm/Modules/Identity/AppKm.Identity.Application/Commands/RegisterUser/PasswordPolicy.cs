using Platform.SharedKernel.Results;

namespace AppKm.Identity.Application.Commands.RegisterUser;

internal static class PasswordPolicy
{
    private const int MinimumLength = 8;

    public static Result Validate(string? password)
    {
        if (string.IsNullOrWhiteSpace(password))
        {
            return Result.Failure(
                RegisterUserErrors.PasswordRequired);
        }

        if (password.Length < MinimumLength)
        {
            return Result.Failure(
                RegisterUserErrors.PasswordTooShort);
        }

        if (!password.Any(char.IsUpper))
        {
            return Result.Failure(
                RegisterUserErrors.PasswordRequiresUppercase);
        }

        if (!password.Any(char.IsLower))
        {
            return Result.Failure(
                RegisterUserErrors.PasswordRequiresLowercase);
        }

        if (!password.Any(char.IsDigit))
        {
            return Result.Failure(
                RegisterUserErrors.PasswordRequiresDigit);
        }

        return Result.Success();
    }
}