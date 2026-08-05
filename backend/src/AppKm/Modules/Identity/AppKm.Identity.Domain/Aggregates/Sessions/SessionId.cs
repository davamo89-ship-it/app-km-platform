namespace AppKm.Identity.Domain.Aggregates.Sessions;

public readonly record struct SessionId(Guid Value)
{
    public static SessionId New()
    {
        return new SessionId(Guid.NewGuid());
    }

    public static SessionId From(Guid value)
    {
        if (value == Guid.Empty)
        {
            throw new ArgumentException(
                "The session identifier cannot be empty.",
                nameof(value));
        }

        return new SessionId(value);
    }

    public override string ToString()
    {
        return Value.ToString();
    }
}