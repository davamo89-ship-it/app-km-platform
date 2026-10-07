namespace AppKm.Athletes.Application.Commands.SyncStravaActivities;

public sealed record ActivitySyncDecision(
    long StravaActivityId,
    string Status,
    int EvidenceScore,
    int FraudRiskScore,
    IReadOnlyList<string> Reasons);
