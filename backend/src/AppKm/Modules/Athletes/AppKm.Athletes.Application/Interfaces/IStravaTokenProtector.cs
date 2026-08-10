namespace AppKm.Athletes.Application.Interfaces;

public interface IStravaTokenProtector
{
    string Protect(string token);

    string Unprotect(string protectedToken);
}