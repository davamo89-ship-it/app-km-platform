namespace AppKm.Identity.Application.Interfaces;

public interface IRefreshTokenGenerator
{
    RefreshTokenResult Generate();

    string Hash(string refreshToken);
}

public sealed record RefreshTokenResult(
    string Token,
    string TokenHash);