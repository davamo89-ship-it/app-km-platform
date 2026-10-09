using Platform.SharedKernel.Errors;

namespace AppKm.Identity.Application.Commands.ProvisionCognitoUser;

public static class ProvisionCognitoUserErrors
{
    public static readonly Error EmailAlreadyUsed = new(
        "Identity.Cognito.EmailAlreadyUsed",
        "The email is already linked to another App KM account.");

    public static readonly Error InvalidUser = new(
        "Identity.Cognito.InvalidUser",
        "The Cognito user could not be provisioned.");
}
