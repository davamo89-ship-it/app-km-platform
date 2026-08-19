namespace AppKm.Athletes.Application.Commands.SyncStravaActivities;

public sealed record SyncStravaActivitiesResult(
    int Retrieved,
    int Saved,
    int SkippedInvalid,
    int SkippedDuplicate);