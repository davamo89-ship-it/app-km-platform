namespace AppKm.Athletes.Application.Activities;

public sealed record ActivityFraudAssessment(
    ActivityFraudStatus Status,
    int EvidenceScore,
    int FraudRiskScore,
    IReadOnlyList<string> Reasons)
{
    public bool EligibleForPoints =>
        Status == ActivityFraudStatus.Valid;
}
