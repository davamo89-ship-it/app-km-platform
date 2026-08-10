namespace AppKm.Athletes.Application.Commands.ConnectStrava;

public sealed record ConnectStravaResult(
    long StravaAthleteId,
    DateTimeOffset ConnectedAtUtc);