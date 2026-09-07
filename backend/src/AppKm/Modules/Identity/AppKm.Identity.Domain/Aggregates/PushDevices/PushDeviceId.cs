namespace AppKm.Identity.Domain.Aggregates.PushDevices;

public readonly record struct PushDeviceId(Guid Value)
{
    public static PushDeviceId New()
    {
        return new PushDeviceId(Guid.NewGuid());
    }

    public static PushDeviceId From(Guid value)
    {
        if (value == Guid.Empty)
        {
            throw new ArgumentException(
                "The push device identifier cannot be empty.",
                nameof(value));
        }

        return new PushDeviceId(value);
    }

    public override string ToString()
    {
        return Value.ToString();
    }
}
