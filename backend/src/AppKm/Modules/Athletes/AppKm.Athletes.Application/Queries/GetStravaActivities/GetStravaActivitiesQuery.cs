namespace AppKm.Athletes.Application.Queries.GetStravaActivities;

public sealed record GetStravaActivitiesQuery(
    Guid UserId,
    DateTimeOffset? After,
    DateTimeOffset? Before,
    int Page = 1,
    int PerPage = 30);