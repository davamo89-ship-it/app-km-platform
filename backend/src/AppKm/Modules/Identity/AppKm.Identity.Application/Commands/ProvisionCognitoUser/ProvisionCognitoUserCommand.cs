namespace AppKm.Identity.Application.Commands.ProvisionCognitoUser;

public sealed record ProvisionCognitoUserCommand(
    Guid UserId,
    string Email,
    IReadOnlyCollection<string> Roles);
