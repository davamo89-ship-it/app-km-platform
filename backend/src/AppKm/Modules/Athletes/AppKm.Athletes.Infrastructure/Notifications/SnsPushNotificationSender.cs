using System.Text.Json;
using Amazon.SimpleNotificationService;
using Amazon.SimpleNotificationService.Model;
using AppKm.Athletes.Application.Interfaces;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Npgsql;

namespace AppKm.Athletes.Infrastructure.Notifications;

internal sealed class SnsPushNotificationSender : IPushNotificationSender
{
    private readonly string _identityConnectionString;
    private readonly string _platformApplicationArn;
    private readonly IAmazonSimpleNotificationService _sns;
    private readonly ILogger<SnsPushNotificationSender> _logger;

    public SnsPushNotificationSender(
        IConfiguration configuration,
        IAmazonSimpleNotificationService sns,
        ILogger<SnsPushNotificationSender> logger)
    {
        _identityConnectionString = configuration.GetConnectionString("IdentityDatabase")
            ?? throw new InvalidOperationException("The IdentityDatabase connection string is missing.");
        _platformApplicationArn = configuration["Aws:Sns:PlatformApplicationArn"]
            ?? throw new InvalidOperationException("Aws:Sns:PlatformApplicationArn is missing.");
        _sns = sns;
        _logger = logger;
    }

    public async Task SendRedemptionChangedAsync(
        Guid userId,
        string code,
        string status,
        string title,
        string body,
        CancellationToken cancellationToken)
    {
        IReadOnlyList<string> tokens = await GetActiveTokensAsync(userId, cancellationToken);

        foreach (string token in tokens)
        {
            try
            {
                CreatePlatformEndpointResponse endpoint = await _sns.CreatePlatformEndpointAsync(
                    new CreatePlatformEndpointRequest
                    {
                        PlatformApplicationArn = _platformApplicationArn,
                        Token = token,
                        CustomUserData = userId.ToString("D")
                    },
                    cancellationToken);

                string fcmMessage = JsonSerializer.Serialize(new
                {
                    fcmV1Message = new
                    {
                        validate_only = false,
                        message = new
                        {
                            notification = new { title, body },
                            data = new
                            {
                                type = "redemption_changed",
                                code,
                                status
                            },
                            android = new { priority = "high" }
                        }
                    }
                });

                string snsMessage = JsonSerializer.Serialize(new Dictionary<string, string>
                {
                    ["default"] = body,
                    ["GCM"] = fcmMessage
                });

                await _sns.PublishAsync(
                    new PublishRequest
                    {
                        TargetArn = endpoint.EndpointArn,
                        Message = snsMessage,
                        MessageStructure = "json"
                    },
                    cancellationToken);
            }
            catch (AmazonSimpleNotificationServiceException exception)
            {
                _logger.LogWarning(
                    exception,
                    "SNS could not deliver a redemption notification to user {UserId}.",
                    userId);
            }
        }
    }

    private async Task<IReadOnlyList<string>> GetActiveTokensAsync(
        Guid userId,
        CancellationToken cancellationToken)
    {
        var tokens = new List<string>();

        await using var connection = new NpgsqlConnection(_identityConnectionString);
        await connection.OpenAsync(cancellationToken);

        const string sql =
            "SELECT token FROM identity.push_devices " +
            "WHERE user_id = @user_id AND is_active = TRUE " +
            "ORDER BY updated_at_utc DESC;";

        await using var command = new NpgsqlCommand(sql, connection);
        command.Parameters.AddWithValue("user_id", userId);

        await using var reader = await command.ExecuteReaderAsync(cancellationToken);
        while (await reader.ReadAsync(cancellationToken))
        {
            string token = reader.GetString(0).Trim();
            if (!string.IsNullOrWhiteSpace(token))
            {
                tokens.Add(token);
            }
        }

        return tokens;
    }
}
