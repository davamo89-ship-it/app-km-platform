using AppKm.Athletes.Application.Activities;
using AppKm.Athletes.Application.Interfaces;
using AppKm.Athletes.Domain.Activities;
using AppKm.Athletes.Domain.Aggregates.Athletes;
using AppKm.Athletes.Domain.Aggregates.AthleteActivities;
using AppKm.Athletes.Domain.Aggregates.StravaConnections;
using AppKm.Athletes.Domain.Aggregates.PointTransactions;
using Platform.SharedKernel.Errors;
using Platform.SharedKernel.Results;


namespace AppKm.Athletes.Application.Commands.SyncStravaActivities;

public sealed class SyncStravaActivitiesCommandHandler
{
    private readonly IAthleteRepository _athleteRepository;
    private readonly IStravaConnectionRepository _connectionRepository;
    private readonly IStravaAccessTokenService _accessTokenService;
    private readonly IStravaActivitiesClient _activitiesClient;
    private readonly IAthleteActivityRepository _activityRepository;
    private readonly IAthleteUnitOfWork _unitOfWork;
    private readonly IPointTransactionRepository _pointTransactionRepository;

    private readonly StravaActivityValidator _validator =
        new();

    private readonly StravaActivityNormalizer _normalizer =
        new();

    private readonly ActivityPointsCalculator _pointsCalculator =
        new();

    private readonly ActivityFraudEvaluator _fraudEvaluator =
        new();

    public SyncStravaActivitiesCommandHandler(
        IAthleteRepository athleteRepository,
        IStravaConnectionRepository connectionRepository,
        IStravaAccessTokenService accessTokenService,
        IStravaActivitiesClient activitiesClient,
        IAthleteActivityRepository activityRepository,
        IAthleteUnitOfWork unitOfWork,
        IPointTransactionRepository pointTransactionRepository)
    {
        _athleteRepository = athleteRepository;
        _connectionRepository = connectionRepository;
        _accessTokenService = accessTokenService;
        _activitiesClient = activitiesClient;
        _activityRepository = activityRepository;
        _unitOfWork = unitOfWork;
        _pointTransactionRepository = pointTransactionRepository;
    }

    public async Task<Result<SyncStravaActivitiesResult>> HandleAsync(
        SyncStravaActivitiesCommand command,
        CancellationToken cancellationToken)
    {
        Athlete? athlete =
            await _athleteRepository.GetByUserIdAsync(
                command.UserId,
                cancellationToken);

        if (athlete is null)
        {
            return Result<SyncStravaActivitiesResult>.Failure(
                new Error(
                    "Athletes.Profile.NotFound",
                    "The athlete profile was not found."));
        }

        StravaConnection? connection =
            await _connectionRepository.GetByAthleteIdAsync(
                athlete.Id.Value,
                cancellationToken);

        if (connection is null ||
            connection.Status != StravaConnectionStatus.Active)
        {
            return Result<SyncStravaActivitiesResult>.Failure(
                new Error(
                    "Athletes.Strava.NotConnected",
                    "The athlete does not have an active Strava connection."));
        }

        string accessToken =
            await _accessTokenService.GetValidAccessTokenAsync(
                connection,
                cancellationToken);

        DateTimeOffset now =
            DateTimeOffset.Now;

        DateTimeOffset startOfToday =
            new(
                now.Year,
                now.Month,
                now.Day,
                0,
                0,
                0,
                now.Offset);

        DateTimeOffset startOfTomorrow =
            startOfToday.AddDays(1);

        IReadOnlyList<StravaActivityResult> activities =
            await _activitiesClient.GetActivitiesAsync(
                accessToken,
                startOfToday,
                startOfTomorrow,
                1,
                100,
                cancellationToken);

        IReadOnlyList<AthleteActivity> history =
            await _activityRepository.GetAllByAthleteAsync(
                athlete.Id,
                cancellationToken);

        int saved = 0;
        int skippedInvalid = 0;
        int skippedDuplicate = 0;
        int skippedReview = 0;
        int skippedIneligible = 0;

        var decisions =
            new List<ActivitySyncDecision>();

        foreach (StravaActivityResult activity in activities)
        {
            ActivityValidationResult validation =
                _validator.Validate(
                    activity,
                    now);

            if (!validation.IsValid)
            {
                skippedInvalid++;

                decisions.Add(
                    new ActivitySyncDecision(
                        activity.Id,
                        ActivityFraudStatus.Invalid.ToString(),
                        0,
                        100,
                        new[]
                        {
                            validation.Reason ??
                            "BaseValidationFailed"
                        }));

                continue;
            }

            bool alreadyExists =
                await _activityRepository
                    .ExistsByStravaActivityIdAsync(
                        athlete.Id,
                        activity.Id,
                        cancellationToken);

            if (alreadyExists)
            {
                skippedDuplicate++;

                decisions.Add(
                    new ActivitySyncDecision(
                        activity.Id,
                        ActivityFraudStatus.Ineligible.ToString(),
                        100,
                        100,
                        new[] { "DuplicateActivity" }));

                continue;
            }

            AppKmActivityType activityType =
                StravaSportTypeMapper.Map(activity.SportType)!.Value;

            ActivityFraudAssessment fraudAssessment =
                _fraudEvaluator.Evaluate(
                    activity,
                    activityType,
                    history);

            if (!fraudAssessment.EligibleForPoints)
            {
                switch (fraudAssessment.Status)
                {
                    case ActivityFraudStatus.Review:
                        skippedReview++;
                        break;

                    case ActivityFraudStatus.Ineligible:
                        skippedIneligible++;
                        break;

                    default:
                        skippedInvalid++;
                        break;
                }

                decisions.Add(
                    new ActivitySyncDecision(
                        activity.Id,
                        fraudAssessment.Status.ToString(),
                        fraudAssessment.EvidenceScore,
                        fraudAssessment.FraudRiskScore,
                        fraudAssessment.Reasons));

                continue;
            }

            NormalizedActivity normalized =
                _normalizer.Normalize(activity);

            int points =
                _pointsCalculator.Calculate(
                    normalized.ActivityType,
                    normalized.DistanceKilometers);

            AthleteActivity entity =
                AthleteActivity.Create(
                    athlete.Id,
                    normalized.StravaActivityId,
                    normalized.ActivityType,
                    normalized.DistanceKilometers,
                    points,
                    normalized.StartDateUtc,
                    normalized.StartDateLocal,
                    normalized.ElapsedTimeSeconds,
                    normalized.MovingTimeSeconds,
                    DateTimeOffset.UtcNow);

            await _activityRepository.AddAsync(
                entity,
                cancellationToken);

            if (entity.Points > 0)
            {
                bool earnedAlreadyExists =
                    await _pointTransactionRepository
                        .ExistsEarnedForActivityAsync(
                            athlete.Id.Value,
                            entity.Id.Value,
                            cancellationToken);

                if (!earnedAlreadyExists)
                {
                    PointTransaction transaction =
                        PointTransaction.CreateEarned(
                            athlete.Id.Value,
                            entity.Id.Value,
                            entity.Points,
                            DateTimeOffset.UtcNow);

                    await _pointTransactionRepository.AddAsync(
                        transaction,
                        cancellationToken);
                }
            }

            saved++;
        }

        await _unitOfWork.SaveChangesAsync(
            cancellationToken);

        return Result<SyncStravaActivitiesResult>.Success(
            new SyncStravaActivitiesResult(
                activities.Count,
                saved,
                skippedInvalid,
                skippedDuplicate,
                skippedReview,
                skippedIneligible,
                decisions));
    }
}
