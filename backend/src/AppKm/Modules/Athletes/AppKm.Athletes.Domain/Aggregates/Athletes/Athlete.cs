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
   
    public string? ProfileImageUrl { get; private set; }

    public string? CountryCode { get; private set; }

    public DateOnly? BirthDate { get; private set; }

    public string? PreferredSport { get; private set; }

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

    public void UpdateProfile(
    string displayName,
    string? profileImageUrl,
    string? countryCode,
    DateOnly? birthDate,
    string? preferredSport,
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

    if (!string.IsNullOrWhiteSpace(countryCode) &&
        countryCode.Trim().Length != 2)
    {
        throw new ArgumentException(
            "CountryCode must use ISO 3166-1 alpha-2 format.",
            nameof(countryCode));
    }

    DisplayName =
        normalizedDisplayName;

    ProfileImageUrl =
        string.IsNullOrWhiteSpace(profileImageUrl)
            ? null
            : profileImageUrl.Trim();

    CountryCode =
        string.IsNullOrWhiteSpace(countryCode)
            ? null
            : countryCode.Trim().ToUpperInvariant();

    BirthDate =
        birthDate;

    PreferredSport =
        string.IsNullOrWhiteSpace(preferredSport)
            ? null
            : preferredSport.Trim();

    UpdatedAtUtc =
        updatedAtUtc;
}
}