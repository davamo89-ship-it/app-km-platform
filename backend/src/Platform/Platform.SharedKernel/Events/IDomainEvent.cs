namespace Platform.SharedKernel.Events;

public interface IDomainEvent
{
    Guid Id { get; }

    DateTimeOffset OccurredOnUtc { get; }
}