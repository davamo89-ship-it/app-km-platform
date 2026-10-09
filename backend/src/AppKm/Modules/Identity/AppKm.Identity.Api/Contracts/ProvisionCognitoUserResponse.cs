namespace AppKm.Identity.Api.Contracts;

public sealed record ProvisionCognitoUserResponse(
    Guid UserId,
    string Email,
    IReadOnlyCollection<string> Roles);
