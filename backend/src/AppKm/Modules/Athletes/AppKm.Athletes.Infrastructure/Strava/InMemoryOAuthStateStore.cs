using System.Collections.Concurrent;
using AppKm.Athletes.Application.Interfaces;

namespace AppKm.Athletes.Infrastructure.Strava;

internal sealed class InMemoryOAuthStateStore
    : IOAuthStateStore
{
    private readonly ConcurrentDictionary<string, Guid> _states =
        new();

    public void Store(
        string state,
        Guid userId)
    {
        _states[state] = userId;
    }

    public bool TryConsume(
        string state,
        out Guid userId)
    {
        return _states.TryRemove(
            state,
            out userId);
    }
}