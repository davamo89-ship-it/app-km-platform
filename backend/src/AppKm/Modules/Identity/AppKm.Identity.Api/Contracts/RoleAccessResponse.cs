namespace AppKm.Identity.Api.Contracts;

public sealed record RoleAccessResponse(
    string Message,
    string RequiredRole);