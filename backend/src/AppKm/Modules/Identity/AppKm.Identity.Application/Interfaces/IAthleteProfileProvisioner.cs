namespace AppKm.Identity.Application.Interfaces;

public interface IAthleteProfileProvisioner
{
    Task CreateAsync(
        Guid userId,
        string displayName,
        DateTimeOffset registeredAtUtc,
        CancellationToken cancellationToken);
}