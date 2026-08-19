namespace AppKm.Athletes.Application.Points;

public sealed record ExpirePointsResult(
    int ExpiredLots,
    int ExpiredPoints);