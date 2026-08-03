namespace AppKm.Identity.Api.Contracts;

public sealed record ErrorResponse(
    string Code,
    string Message);