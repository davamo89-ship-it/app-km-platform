[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$IdentityBaseUrl,

    [Parameter(Mandatory = $true)]
    [string]$AthletesBaseUrl
)

$ErrorActionPreference = "Stop"

function Test-Endpoint {
    param(
        [string]$Name,
        [string]$Url
    )

    Write-Host "Probando $Name -> $Url"

    $response =
        Invoke-WebRequest `
            -Uri $Url `
            -Method Get `
            -Headers @{
                "X-Forwarded-Proto" = "https"
            } `
            -MaximumRedirection 0 `
            -SkipHttpErrorCheck

    if ($response.StatusCode -ne 200) {
        throw "$Name devolvió HTTP $($response.StatusCode)."
    }

    Write-Host "OK: HTTP 200"
}

Test-Endpoint `
    -Name "Identity liveness" `
    -Url "$($IdentityBaseUrl.TrimEnd('/'))/health/live"

Test-Endpoint `
    -Name "Identity readiness" `
    -Url "$($IdentityBaseUrl.TrimEnd('/'))/health/ready"

Test-Endpoint `
    -Name "Athletes liveness" `
    -Url "$($AthletesBaseUrl.TrimEnd('/'))/health/live"

Test-Endpoint `
    -Name "Athletes readiness" `
    -Url "$($AthletesBaseUrl.TrimEnd('/'))/health/ready"

Write-Host ""
Write-Host "Smoke test de staging completado."
