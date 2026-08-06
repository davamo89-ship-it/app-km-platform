namespace AppKm.Identity.Domain.Aggregates.Roles;

public static class RoleIds
{
    public static readonly RoleId Athlete =
        RoleId.From(
            Guid.Parse("11111111-1111-1111-1111-111111111111"));

    public static readonly RoleId Merchant =
        RoleId.From(
            Guid.Parse("22222222-2222-2222-2222-222222222222"));

    public static readonly RoleId Admin =
        RoleId.From(
            Guid.Parse("33333333-3333-3333-3333-333333333333"));
}