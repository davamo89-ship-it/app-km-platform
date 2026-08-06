using Platform.SharedKernel.Entities;

namespace AppKm.Identity.Domain.Aggregates.Roles;

public sealed class Role : AggregateRoot<RoleId>
{
    private Role()
        : base(default)
    {
        Name = string.Empty;
    }

    private Role(
        RoleId id,
        string name)
        : base(id)
    {
        Name = name;
    }

    public string Name { get; private set; }

    public static Role Create(
        RoleId id,
        string name)
    {
        if (id.Value == Guid.Empty)
        {
            throw new ArgumentException(
                "The role identifier cannot be empty.",
                nameof(id));
        }

        ArgumentException.ThrowIfNullOrWhiteSpace(name);

        if (!RoleNames.IsValid(name))
        {
            throw new ArgumentOutOfRangeException(
                nameof(name),
                name,
                "The role name is not supported.");
        }

        return new Role(
            id,
            name);
    }
}