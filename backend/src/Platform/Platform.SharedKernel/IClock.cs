namespace Platform.SharedKernel.Abstractions;

public interface IClock
{
    DateTimeOffset UtcNow { get; }
}
