namespace AppKm.Identity.Domain.Aggregates.Users;

public sealed record UserStatus
{
    private UserStatus(string value)
    {
        Value = value;
    }

    public string Value { get; }

    public static readonly UserStatus PendingVerification =
        new("PendingVerification");

    public static readonly UserStatus Active =
        new("Active");

    public static readonly UserStatus Suspended =
        new("Suspended");

    public static readonly UserStatus Deactivated =
        new("Deactivated");

    public override string ToString()
    {
        return Value;
    }
}