namespace AppKm.Identity.Application.Commands.ProvisionCognitoUser;

public sealed record ProvisionCognitoUserResult(
    Guid UserId,
    string Email,
    IReadOnlyCollection<string> Roles);
