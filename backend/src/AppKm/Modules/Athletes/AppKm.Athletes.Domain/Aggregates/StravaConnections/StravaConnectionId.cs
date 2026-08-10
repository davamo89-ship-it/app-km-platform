namespace AppKm.Athletes.Domain.Aggregates.StravaConnections;

public readonly record struct StravaConnectionId(Guid Value)
{
    public static StravaConnectionId New()
    {
        return new StravaConnectionId(Guid.NewGuid());
    }

    public static StravaConnectionId From(Guid value)
    {
        if (value == Guid.Empty)
        {
            throw new ArgumentException(
                "The Strava connection identifier cannot be empty.",
                nameof(value));
        }

        return new StravaConnectionId(value);
    }

    public override string ToString()
    {
        return Value.ToString();
    }
}