namespace AppKm.Athletes.Application.Interfaces;

public interface IOAuthStateStore
{
    void Store(
        string state,
        Guid userId);

    bool TryConsume(
        string state,
        out Guid userId);
}