namespace AppKm.Athletes.Application.Queries.GetAthleteDashboard;

public sealed record DashboardActivityResult(
    long StravaActivityId,
    string ActivityType,
    double DistanceKilometers,
    int Points,
    DateTimeOffset StartDateUtc);