namespace AppKm.Athletes.Application.Interfaces;

public interface IStravaTokenRevocationService
{
    Task RevokeAsync(
        string protectedToken,
        CancellationToken cancellationToken);
}