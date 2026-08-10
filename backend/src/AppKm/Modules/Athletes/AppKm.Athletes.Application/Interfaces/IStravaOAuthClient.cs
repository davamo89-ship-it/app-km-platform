namespace AppKm.Athletes.Application.Interfaces;

public interface IStravaOAuthClient
{
    Task<StravaTokenExchangeResult> ExchangeCodeAsync(
        string code,
        CancellationToken cancellationToken);
}