namespace AppKm.Identity.Domain.Aggregates.Roles;

public static class RoleNames
{
    public const string Athlete = "Athlete";

    public const string Merchant = "Merchant";

    public const string Admin = "Admin";

    public static readonly IReadOnlyCollection<string> All =
    [
        Athlete,
        Merchant,
        Admin
    ];

    public static bool IsValid(string roleName)
    {
        return All.Contains(
            roleName,
            StringComparer.Ordinal);
    }
}