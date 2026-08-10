namespace AppKm.Athletes.Application.Commands.DisconnectStrava;

public sealed record DisconnectStravaResult(
    Guid AthleteId,
    string Status,
    DateTimeOffset DisconnectedAtUtc);