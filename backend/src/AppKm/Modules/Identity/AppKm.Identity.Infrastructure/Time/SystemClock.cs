using Platform.SharedKernel.Abstractions;

namespace AppKm.Identity.Infrastructure.Time;

internal sealed class SystemClock : IClock
{
    public DateTimeOffset UtcNow => DateTimeOffset.UtcNow;
}