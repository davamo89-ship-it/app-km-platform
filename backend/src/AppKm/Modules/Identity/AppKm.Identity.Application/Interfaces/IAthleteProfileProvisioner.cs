namespace AppKm.Identity.Application.Interfaces;

public interface IAthleteProfileProvisioner
{
    Task CreateAsync(
        Guid userId,
        string displayName,
        CancellationToken cancellationToken);
}