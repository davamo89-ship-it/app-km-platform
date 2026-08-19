namespace AppKm.Athletes.Application.Activities;

public sealed record ActivityValidationResult(
    bool IsValid,
    string? Reason)
{
    public static ActivityValidationResult Valid() =>
        new(true, null);

    public static ActivityValidationResult Invalid(
        string reason) =>
        new(false, reason);
}