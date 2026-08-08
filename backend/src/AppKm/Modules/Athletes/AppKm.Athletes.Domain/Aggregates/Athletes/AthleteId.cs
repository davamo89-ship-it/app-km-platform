namespace AppKm.Athletes.Domain.Aggregates.Athletes;

public readonly record struct AthleteId(Guid Value)
{
    public static AthleteId New()
    {
        return new AthleteId(Guid.NewGuid());
    }

    public static AthleteId From(Guid value)
    {
        if (value == Guid.Empty)
        {
            throw new ArgumentException(
                "The athlete identifier cannot be empty.",
                nameof(value));
        }

        return new AthleteId(value);
    }

    public override string ToString()
    {
        return Value.ToString();
    }
}