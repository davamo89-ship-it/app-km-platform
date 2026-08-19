namespace AppKm.Athletes.Application.Commands.SyncStravaActivities;

public sealed record SyncStravaActivitiesCommand(
    Guid UserId);