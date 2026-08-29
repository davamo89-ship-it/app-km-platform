namespace AppKm.Athletes.Application.Queries.GetAthleteDashboard;

public sealed record GetAthleteDashboardResult(
    Guid AthleteId,
    string DisplayName,
    string? ProfileImageUrl,
    int PointsBalance,
    bool StravaConnected,
    string? StravaStatus,
    DashboardActivityResult? LastActivity,
    int PointsExpiringSoon,
    double TotalKilometers,
    int ApprovedActivities,
    int CurrentStreakDays,
    double MonthlyKilometers);