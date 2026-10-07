using System.Threading;

namespace Platform.SharedKernel.Observability;

public sealed class OperationalMetrics
{
    private readonly string _service;
    private readonly DateTimeOffset _startedAtUtc;

    private long _completedRequests;
    private long _clientErrorRequests;
    private long _serverErrorRequests;
    private long _activeRequests;
    private long _totalDurationMicroseconds;
    private long _maxDurationMicroseconds;
    private long _lastRequestUnixMilliseconds;

    public OperationalMetrics(string service)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(service);

        _service = service;
        _startedAtUtc = DateTimeOffset.UtcNow;
    }

    public void RequestStarted()
    {
        Interlocked.Increment(ref _activeRequests);
    }

    public void RequestCompleted(
        int statusCode,
        TimeSpan duration,
        DateTimeOffset completedAtUtc)
    {
        Interlocked.Decrement(ref _activeRequests);
        Interlocked.Increment(ref _completedRequests);

        if (statusCode >= 500)
        {
            Interlocked.Increment(ref _serverErrorRequests);
        }
        else if (statusCode >= 400)
        {
            Interlocked.Increment(ref _clientErrorRequests);
        }

        long durationMicroseconds =
            Math.Max(
                0,
                (long)Math.Round(
                    duration.TotalMilliseconds * 1000d));

        Interlocked.Add(
            ref _totalDurationMicroseconds,
            durationMicroseconds);

        UpdateMax(
            durationMicroseconds);

        Interlocked.Exchange(
            ref _lastRequestUnixMilliseconds,
            completedAtUtc.ToUnixTimeMilliseconds());
    }

    public OperationalMetricsSnapshot GetSnapshot()
    {
        long completed =
            Interlocked.Read(ref _completedRequests);

        long totalDurationMicroseconds =
            Interlocked.Read(ref _totalDurationMicroseconds);

        long maxDurationMicroseconds =
            Interlocked.Read(ref _maxDurationMicroseconds);

        long lastRequestUnixMilliseconds =
            Interlocked.Read(ref _lastRequestUnixMilliseconds);

        double averageDurationMilliseconds =
            completed == 0
                ? 0d
                : totalDurationMicroseconds /
                  1000d /
                  completed;

        DateTimeOffset? lastRequestUtc =
            lastRequestUnixMilliseconds <= 0
                ? null
                : DateTimeOffset.FromUnixTimeMilliseconds(
                    lastRequestUnixMilliseconds);

        return new OperationalMetricsSnapshot(
            _service,
            _startedAtUtc,
            DateTimeOffset.UtcNow,
            completed,
            Interlocked.Read(ref _clientErrorRequests),
            Interlocked.Read(ref _serverErrorRequests),
            Interlocked.Read(ref _activeRequests),
            Math.Round(
                averageDurationMilliseconds,
                3),
            Math.Round(
                maxDurationMicroseconds / 1000d,
                3),
            lastRequestUtc);
    }

    private void UpdateMax(
        long candidateMicroseconds)
    {
        while (true)
        {
            long current =
                Interlocked.Read(
                    ref _maxDurationMicroseconds);

            if (candidateMicroseconds <= current)
            {
                return;
            }

            long original =
                Interlocked.CompareExchange(
                    ref _maxDurationMicroseconds,
                    candidateMicroseconds,
                    current);

            if (original == current)
            {
                return;
            }
        }
    }
}

public sealed record OperationalMetricsSnapshot(
    string Service,
    DateTimeOffset StartedAtUtc,
    DateTimeOffset CapturedAtUtc,
    long TotalRequests,
    long ClientErrorRequests,
    long ServerErrorRequests,
    long ActiveRequests,
    double AverageDurationMilliseconds,
    double MaxDurationMilliseconds,
    DateTimeOffset? LastRequestUtc);
