using AppKm.Athletes.Application.Interfaces;
using FirebaseAdmin;
using FirebaseAdmin.Messaging;
using Google.Apis.Auth.OAuth2;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Npgsql;

namespace AppKm.Athletes.Infrastructure.Notifications;

internal sealed class FirebasePushNotificationSender
    : IPushNotificationSender
{
    private const string FirebaseAppName = "AppKmPush";

    private readonly string _identityConnectionString;
    private readonly string? _projectId;
    private readonly ILogger<FirebasePushNotificationSender> _logger;
    private readonly SemaphoreSlim _initializationGate = new(1, 1);

    private FirebaseMessaging? _messaging;
    private bool _initializationAttempted;

    public FirebasePushNotificationSender(
        IConfiguration configuration,
        ILogger<FirebasePushNotificationSender> logger)
    {
        _identityConnectionString =
            configuration.GetConnectionString("IdentityDatabase")
            ?? throw new InvalidOperationException(
                "The IdentityDatabase connection string is missing.");

        _projectId = configuration["Firebase:ProjectId"];
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
        if (userId == Guid.Empty)
        {
            return;
        }

        try
        {
            IReadOnlyList<string> tokens =
                await GetActiveTokensAsync(
                    userId,
                    cancellationToken);

            if (tokens.Count == 0)
            {
                return;
            }

            FirebaseMessaging? messaging =
                await GetMessagingAsync(cancellationToken);

            if (messaging is null)
            {
                return;
            }

            foreach (string token in tokens)
            {
                var message = new Message
                {
                    Token = token,
                    Notification = new Notification
                    {
                        Title = title,
                        Body = body
                    },
                    Data = new Dictionary<string, string>
                    {
                        ["type"] = "redemption_changed",
                        ["code"] = code,
                        ["status"] = status
                    }
                };

                try
                {
                    await messaging.SendAsync(
                        message,
                        cancellationToken);
                }
                catch (FirebaseMessagingException exception)
                {
                    _logger.LogWarning(
                        exception,
                        "FCM could not deliver a redemption notification " +
                        "to one registered device for user {UserId}.",
                        userId);
                }
            }
        }
        catch (OperationCanceledException)
            when (cancellationToken.IsCancellationRequested)
        {
            throw;
        }
        catch (Exception exception)
        {
            _logger.LogWarning(
                exception,
                "FCM redemption notification failed for user {UserId}.",
                userId);
        }
    }

    private async Task<IReadOnlyList<string>> GetActiveTokensAsync(
        Guid userId,
        CancellationToken cancellationToken)
    {
        var tokens = new List<string>();

        await using var connection =
            new NpgsqlConnection(_identityConnectionString);

        await connection.OpenAsync(cancellationToken);

        const string sql =
            "SELECT token " +
            "FROM identity.push_devices " +
            "WHERE user_id = @user_id " +
            "AND is_active = TRUE " +
            "ORDER BY updated_at_utc DESC;";

        await using var command =
            new NpgsqlCommand(sql, connection);

        command.Parameters.AddWithValue(
            "user_id",
            userId);

        await using var reader =
            await command.ExecuteReaderAsync(cancellationToken);

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

    private async Task<FirebaseMessaging?> GetMessagingAsync(
        CancellationToken cancellationToken)
    {
        if (_messaging is not null)
        {
            return _messaging;
        }

        if (_initializationAttempted)
        {
            return null;
        }

        await _initializationGate.WaitAsync(cancellationToken);

        try
        {
            if (_messaging is not null)
            {
                return _messaging;
            }

            if (_initializationAttempted)
            {
                return null;
            }

            _initializationAttempted = true;

            if (string.IsNullOrWhiteSpace(_projectId))
            {
                _logger.LogWarning(
                    "FCM is disabled because Firebase:ProjectId is missing.");

                return null;
            }

            GoogleCredential credential =
                await GoogleCredential
                    .GetApplicationDefaultAsync(cancellationToken);

            FirebaseApp app = FirebaseApp.Create(
                new AppOptions
                {
                    Credential = credential,
                    ProjectId = _projectId.Trim()
                },
                FirebaseAppName);

            _messaging = FirebaseMessaging.GetMessaging(app);

            _logger.LogInformation(
                "Firebase Admin initialized for project {ProjectId}.",
                _projectId.Trim());

            return _messaging;
        }
        catch (Exception exception)
        {
            _logger.LogWarning(
                exception,
                "Firebase Admin could not be initialized. " +
                "Verify GOOGLE_APPLICATION_CREDENTIALS and Firebase:ProjectId.");

            return null;
        }
        finally
        {
            _initializationGate.Release();
        }
    }
}
