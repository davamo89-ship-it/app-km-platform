using AppKm.Identity.Domain.ValueObjects;
using Platform.SharedKernel.Events;

namespace AppKm.Identity.Domain.Aggregates.Users.Events;

public sealed record UserRegisteredDomainEvent(
    Guid Id,
    UserId UserId,
    Email Email,
    DateTimeOffset OccurredOnUtc) : IDomainEvent;