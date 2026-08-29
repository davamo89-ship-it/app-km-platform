using AppKm.Athletes.Application.Interfaces;
using AppKm.Athletes.Application.Points;
using AppKm.Athletes.Domain.Aggregates.Athletes;
using AppKm.Athletes.Domain.Aggregates.AthleteActivities;
using AppKm.Athletes.Domain.Aggregates.StravaConnections;
using Platform.SharedKernel.Errors;
using Platform.SharedKernel.Results;

namespace AppKm.Athletes.Application.Queries.GetAthleteDashboard;

public sealed class GetAthleteDashboardQueryHandler
{
    private readonly IAthleteRepository _athleteRepository;
    private readonly IAthleteActivityRepository _activityRepository;
    private readonly IPointTransactionRepository _pointTransactionRepository;
    private readonly IStravaConnectionRepository _stravaConnectionRepository;
    private readonly PointLotCalculator _pointLotCalculator;

    public GetAthleteDashboardQueryHandler(
        IAthleteRepository athleteRepository,
        IAthleteActivityRepository activityRepository,
        IPointTransactionRepository pointTransactionRepository,
        IStravaConnectionRepository stravaConnectionRepository)
    {
        _athleteRepository = athleteRepository;
        _activityRepository = activityRepository;
        _pointTransactionRepository = pointTransactionRepository;
        _stravaConnectionRepository = stravaConnectionRepository;
        _pointLotCalculator = new PointLotCalculator();
    }

    public async Task<Result<GetAthleteDashboardResult>> HandleAsync(
        Guid userId,
        DateTimeOffset now,
        CancellationToken cancellationToken)
    {
        Athlete? athlete =
            await _athleteRepository.GetByUserIdAsync(
                userId,
                cancellationToken);

        if (athlete is null)
        {
            return Result<GetAthleteDashboardResult>.Failure(
                new Error(
                    "Athletes.Profile.NotFound",
                    "The athlete profile was not found."));
        }

        int balance =
            await _pointTransactionRepository.GetBalanceAsync(
                athlete.Id.Value,
                cancellationToken);

        StravaConnection? stravaConnection =
            await _stravaConnectionRepository.GetByAthleteIdAsync(
                athlete.Id.Value,
                cancellationToken);

        AthleteActivity? latestActivity =
            await _activityRepository.GetLatestAsync(
                athlete.Id,
                cancellationToken);
        IReadOnlyList<AthleteActivity> activities =
            await _activityRepository.GetAllByAthleteAsync(
                athlete.Id,
                cancellationToken);

        var transactions =
            await _pointTransactionRepository.GetAllByAthleteAsync(
                athlete.Id.Value,
                cancellationToken);

        IReadOnlyList<AvailablePointLot> lots =
            _pointLotCalculator.Calculate(
                transactions);

        int pointsExpiringSoon =
            lots
                .Where(lot =>
                    lot.ExpiresAtUtc > now &&
                    lot.ExpiresAtUtc <= now.AddDays(30))
                .Sum(lot =>
                    lot.RemainingPoints);

        DashboardActivityResult? lastActivity =
            latestActivity is null
                ? null
                : new DashboardActivityResult(
                    latestActivity.StravaActivityId,
                    latestActivity.ActivityType.ToString(),
                    latestActivity.DistanceKilometers,
                    latestActivity.Points,
                    latestActivity.StartDateUtc);

        bool stravaConnected =
            stravaConnection is not null &&
            stravaConnection.Status ==
                StravaConnectionStatus.Active;
        
        double totalKilometers =
                activities.Sum(activity =>
                    activity.DistanceKilometers);

            int approvedActivities =
                activities.Count;

            DateTime currentDate =
                now.UtcDateTime.Date;

            DateTime currentMonthStart =
                new(
                    currentDate.Year,
                    currentDate.Month,
                    1);

            double monthlyKilometers =
                activities
                    .Where(activity =>
                        activity.StartDateLocal >= currentMonthStart)
                    .Sum(activity =>
                        activity.DistanceKilometers);

            int currentStreakDays =
                CalculateCurrentStreak(
                    activities,
                    currentDate);

        return Result<GetAthleteDashboardResult>.Success(
            new GetAthleteDashboardResult(
            athlete.Id.Value,
            athlete.DisplayName,
            athlete.ProfileImageUrl,
            balance,
            stravaConnected,
            stravaConnection?.Status.ToString(),
            lastActivity,
            pointsExpiringSoon,
            totalKilometers,
            approvedActivities,
            currentStreakDays,
            monthlyKilometers));
    }
        private static int CalculateCurrentStreak(
            IReadOnlyList<AthleteActivity> activities,
            DateTime currentDate)
        {
            if (activities.Count == 0)
            {
                return 0;
            }

            List<DateTime> activityDays =
                activities
                    .Select(activity =>
                        activity.StartDateLocal.Date)
                    .Distinct()
                    .OrderByDescending(date => date)
                    .ToList();

            DateTime yesterday =
                currentDate.AddDays(-1);

            if (activityDays[0] != currentDate &&
                activityDays[0] != yesterday)
            {
                return 0;
            }

            int streak = 1;

            DateTime expectedDay =
                activityDays[0].AddDays(-1);

            foreach (DateTime day in activityDays.Skip(1))
            {
                if (day == expectedDay)
                {
                    streak++;
                    expectedDay =
                        expectedDay.AddDays(-1);

                    continue;
                }

                if (day < expectedDay)
                {
                    break;
                }
            }

            return streak;
        } 
}