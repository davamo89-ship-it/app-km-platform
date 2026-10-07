[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Url,

    [int]$Requests = 200,
    [int]$Concurrency = 10,
    [int]$WarmupRequests = 10,
    [string]$BearerToken,
    [int]$TimeoutSeconds = 30
)

$ErrorActionPreference = "Stop"

if ($Requests -lt 1) {
    throw "Requests debe ser mayor que 0."
}

if ($Concurrency -lt 1) {
    throw "Concurrency debe ser mayor que 0."
}

$handler = [System.Net.Http.SocketsHttpHandler]::new()
$handler.MaxConnectionsPerServer = [Math]::Max($Concurrency * 2, 20)

$client = [System.Net.Http.HttpClient]::new($handler)
$client.Timeout = [TimeSpan]::FromSeconds($TimeoutSeconds)

if (-not [string]::IsNullOrWhiteSpace($BearerToken)) {
    $client.DefaultRequestHeaders.Authorization =
        [System.Net.Http.Headers.AuthenticationHeaderValue]::new(
            "Bearer",
            $BearerToken)
}

function Invoke-OneRequest {
    param(
        [System.Net.Http.HttpClient]$Client,
        [string]$TargetUrl
    )

    $sw = [System.Diagnostics.Stopwatch]::StartNew()

    try {
        $response = $Client.GetAsync($TargetUrl).GetAwaiter().GetResult()
        $sw.Stop()

        return [pscustomobject]@{
            Success = $response.IsSuccessStatusCode
            StatusCode = [int]$response.StatusCode
            ElapsedMs = $sw.Elapsed.TotalMilliseconds
            Error = $null
        }
    }
    catch {
        $sw.Stop()

        return [pscustomobject]@{
            Success = $false
            StatusCode = 0
            ElapsedMs = $sw.Elapsed.TotalMilliseconds
            Error = $_.Exception.Message
        }
    }
}

Write-Host "Warmup: $WarmupRequests solicitudes..."

for ($i = 0; $i -lt $WarmupRequests; $i++) {
    $null = Invoke-OneRequest -Client $client -TargetUrl $Url
}

Write-Host "Carga: $Requests solicitudes, concurrencia $Concurrency"

$results =
    1..$Requests |
    ForEach-Object -Parallel {
        $handler = [System.Net.Http.SocketsHttpHandler]::new()
        $client = [System.Net.Http.HttpClient]::new($handler)
        $client.Timeout = [TimeSpan]::FromSeconds($using:TimeoutSeconds)

        if (-not [string]::IsNullOrWhiteSpace($using:BearerToken)) {
            $client.DefaultRequestHeaders.Authorization =
                [System.Net.Http.Headers.AuthenticationHeaderValue]::new(
                    "Bearer",
                    $using:BearerToken)
        }

        $sw = [System.Diagnostics.Stopwatch]::StartNew()

        try {
            $response =
                $client.GetAsync($using:Url).GetAwaiter().GetResult()

            $sw.Stop()

            [pscustomobject]@{
                Success = $response.IsSuccessStatusCode
                StatusCode = [int]$response.StatusCode
                ElapsedMs = $sw.Elapsed.TotalMilliseconds
                Error = $null
            }
        }
        catch {
            $sw.Stop()

            [pscustomobject]@{
                Success = $false
                StatusCode = 0
                ElapsedMs = $sw.Elapsed.TotalMilliseconds
                Error = $_.Exception.Message
            }
        }
        finally {
            $client.Dispose()
            $handler.Dispose()
        }
    } -ThrottleLimit $Concurrency

$ordered =
    @($results.ElapsedMs | Sort-Object)

function Get-Percentile {
    param(
        [double[]]$Values,
        [double]$Percentile
    )

    if ($Values.Count -eq 0) {
        return 0
    }

    $index =
        [Math]::Ceiling(
            ($Percentile / 100) * $Values.Count) - 1

    $index =
        [Math]::Max(
            0,
            [Math]::Min(
                $Values.Count - 1,
                $index))

    return $Values[$index]
}

$successes =
    @($results | Where-Object Success).Count

$failures =
    $Requests - $successes

$p50 = Get-Percentile -Values $ordered -Percentile 50
$p95 = Get-Percentile -Values $ordered -Percentile 95
$p99 = Get-Percentile -Values $ordered -Percentile 99
$average = ($ordered | Measure-Object -Average).Average
$maximum = ($ordered | Measure-Object -Maximum).Maximum

Write-Host ""
Write-Host "===== APP KM LOAD TEST ====="
Write-Host "URL: $Url"
Write-Host "Requests: $Requests"
Write-Host "Concurrency: $Concurrency"
Write-Host "Success: $successes"
Write-Host "Failures: $failures"
Write-Host ("Average ms: {0:N2}" -f $average)
Write-Host ("P50 ms: {0:N2}" -f $p50)
Write-Host ("P95 ms: {0:N2}" -f $p95)
Write-Host ("P99 ms: {0:N2}" -f $p99)
Write-Host ("Max ms: {0:N2}" -f $maximum)

Write-Host ""
Write-Host "Status codes:"

$results |
    Group-Object StatusCode |
    Sort-Object Name |
    ForEach-Object {
        Write-Host "  $($_.Name): $($_.Count)"
    }

if ($failures -gt 0) {
    Write-Warning "$failures solicitudes fallaron."
}
