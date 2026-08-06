namespace AppKm.Identity.Domain.Aggregates.Roles;

public readonly record struct RoleId(Guid Value)
{
    public static RoleId New()
    {
        return new RoleId(Guid.NewGuid());
    }

    public static RoleId From(Guid value)
    {
        if (value == Guid.Empty)
        {
            throw new ArgumentException(
                "The role identifier cannot be empty.",
                nameof(value));
        }

        return new RoleId(value);
    }

    public override string ToString()
    {
        return Value.ToString();
    }
}