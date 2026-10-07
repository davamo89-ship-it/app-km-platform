[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$IdentityBaseUrl,

    [Parameter(Mandatory = $true)]
    [string]$AthletesBaseUrl
)

$ErrorActionPreference = "Stop"

$targets = @(
    @{
        Name = "Identity liveness"
        Url = "$($IdentityBaseUrl.TrimEnd('/'))/health/live"
    },
    @{
        Name = "Identity readiness"
        Url = "$($IdentityBaseUrl.TrimEnd('/'))/health/ready"
    },
    @{
        Name = "Athletes liveness"
        Url = "$($AthletesBaseUrl.TrimEnd('/'))/health/live"
    },
    @{
        Name = "Athletes readiness"
        Url = "$($AthletesBaseUrl.TrimEnd('/'))/health/ready"
    }
)

foreach ($target in $targets) {
    Write-Host "GET $($target.Url)"

    $response =
        Invoke-WebRequest `
            -Uri $target.Url `
            -Method Get `
            -SkipHttpErrorCheck `
            -TimeoutSec 90

    if ($response.StatusCode -ne 200) {
        throw "$($target.Name) devolvió HTTP $($response.StatusCode)."
    }

    Write-Host "OK - $($target.Name)"
}

Write-Host ""
Write-Host "Staging público saludable."
