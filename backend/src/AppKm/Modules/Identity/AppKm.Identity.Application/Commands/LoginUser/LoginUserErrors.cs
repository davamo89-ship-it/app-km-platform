using Platform.SharedKernel.Errors;

namespace AppKm.Identity.Application.Commands.LoginUser;

public static class LoginUserErrors
{
    public static readonly Error InvalidCredentials = new(
        "Identity.Login.InvalidCredentials",
        "The email address or password is incorrect.");

    public static readonly Error AccountNotActive = new(
        "Identity.Login.AccountNotActive",
        "The user account is not active.");
}