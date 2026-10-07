[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$IdentityBaseUrl,

    [Parameter(Mandatory = $true)]
    [string]$AthletesBaseUrl
)

$ErrorActionPreference = "Stop"

function Invoke-HealthCheck {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Url
    )

    Write-Host "GET $Url"

    try {
        $response =
            Invoke-WebRequest `
                -Uri $Url `
                -Method Get `
                -UseBasicParsing `
                -TimeoutSec 90

        $statusCode =
            [int]$response.StatusCode
    }
    catch {
        $webResponse =
            $_.Exception.Response

        if ($null -ne $webResponse) {
            try {
                $statusCode =
                    [int]$webResponse.StatusCode.value__
            }
            catch {
                $statusCode = $null
            }
        }
        else {
            $statusCode = $null
        }

        if ($null -ne $statusCode) {
            throw "$Name devolvió HTTP $statusCode."
        }

        throw "$Name falló: $($_.Exception.Message)"
    }

    if ($statusCode -ne 200) {
        throw "$Name devolvió HTTP $statusCode."
    }

    Write-Host "OK - $Name"
}

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
    Invoke-HealthCheck `
        -Name $target.Name `
        -Url $target.Url
}

Write-Host ""
Write-Host "Staging público saludable."
