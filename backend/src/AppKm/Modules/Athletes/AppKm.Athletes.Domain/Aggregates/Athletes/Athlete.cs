using Platform.SharedKernel.Entities;

namespace AppKm.Athletes.Domain.Aggregates.Athletes;

public sealed class Athlete : AggregateRoot<AthleteId>
{
    private Athlete()
        : base(default)
    {
        DisplayName = string.Empty;
    }

    private Athlete(
        AthleteId id,
        Guid userId,
        string displayName,
        DateTimeOffset createdAtUtc)
        : base(id)
    {
        UserId = userId;
        DisplayName = displayName;
        Status = AthleteStatus.Active;
        CreatedAtUtc = createdAtUtc;
    }

    public Guid UserId { get; private set; }

    public string DisplayName { get; private set; }

    public AthleteStatus Status { get; private set; }

    public DateTimeOffset CreatedAtUtc { get; private set; }

    public DateTimeOffset? UpdatedAtUtc { get; private set; }

    public static Athlete Create(
        AthleteId id,
        Guid userId,
        string displayName,
        DateTimeOffset createdAtUtc)
    {
        if (id.Value == Guid.Empty)
        {
            throw new ArgumentException(
                "The athlete identifier cannot be empty.",
                nameof(id));
        }

        if (userId == Guid.Empty)
        {
            throw new ArgumentException(
                "The user identifier cannot be empty.",
                nameof(userId));
        }

        ArgumentException.ThrowIfNullOrWhiteSpace(
            displayName);

        string normalizedDisplayName =
            displayName.Trim();

        if (normalizedDisplayName.Length > 100)
        {
            throw new ArgumentException(
                "The display name cannot exceed 100 characters.",
                nameof(displayName));
        }

        return new Athlete(
            id,
            userId,
            normalizedDisplayName,
            createdAtUtc);
    }

    public void UpdateDisplayName(
        string displayName,
        DateTimeOffset updatedAtUtc)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(
            displayName);

        string normalizedDisplayName =
            displayName.Trim();

        if (normalizedDisplayName.Length > 100)
        {
            throw new ArgumentException(
                "The display name cannot exceed 100 characters.",
                nameof(displayName));
        }

        DisplayName = normalizedDisplayName;
        UpdatedAtUtc = updatedAtUtc;
    }

    public void Suspend(
        DateTimeOffset updatedAtUtc)
    {
        Status = AthleteStatus.Suspended;
        UpdatedAtUtc = updatedAtUtc;
    }

    public void Activate(
        DateTimeOffset updatedAtUtc)
    {
        Status = AthleteStatus.Active;
        UpdatedAtUtc = updatedAtUtc;
    }
}