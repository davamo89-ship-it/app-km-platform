namespace AppKm.Athletes.Application.Interfaces;

public interface IPushNotificationSender
{
    Task SendRedemptionChangedAsync(
        Guid userId,
        string code,
        string status,
        string title,
        string body,
        CancellationToken cancellationToken);
}
