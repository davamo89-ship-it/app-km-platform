namespace AppKm.Athletes.Application.Queries.GetPointHistory;

public sealed record GetPointHistoryItem(
    string Type,
    int Points,
    DateTimeOffset CreatedAtUtc,
    DateTimeOffset? ExpiresAtUtc);