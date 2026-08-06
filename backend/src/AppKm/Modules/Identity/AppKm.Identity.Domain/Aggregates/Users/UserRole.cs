using AppKm.Identity.Domain.Aggregates.Roles;

namespace AppKm.Identity.Domain.Aggregates.Users;

public sealed class UserRole
{
    private UserRole()
    {
    }

    private UserRole(
        UserId userId,
        RoleId roleId,
        DateTimeOffset assignedAtUtc)
    {
        UserId = userId;
        RoleId = roleId;
        AssignedAtUtc = assignedAtUtc;
    }

    public UserId UserId { get; private set; }

    public RoleId RoleId { get; private set; }

    public DateTimeOffset AssignedAtUtc { get; private set; }

    public static UserRole Create(
        UserId userId,
        RoleId roleId,
        DateTimeOffset assignedAtUtc)
    {
        if (userId.Value == Guid.Empty)
        {
            throw new ArgumentException(
                "The user identifier cannot be empty.",
                nameof(userId));
        }

        if (roleId.Value == Guid.Empty)
        {
            throw new ArgumentException(
                "The role identifier cannot be empty.",
                nameof(roleId));
        }

        return new UserRole(
            userId,
            roleId,
            assignedAtUtc);
    }
}