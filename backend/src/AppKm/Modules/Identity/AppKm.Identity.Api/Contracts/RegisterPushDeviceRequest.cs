namespace AppKm.Identity.Api.Contracts;

public sealed record RegisterPushDeviceRequest(
    string Token,
    string Platform);
