[CmdletBinding()]
param(
    [string]$Region = 'us-east-1',
    [string]$StackName = 'appkm-staging'
)
$ErrorActionPreference = 'Stop'

function Get-Output([string]$Key) {
    $value = aws cloudformation describe-stacks `
        --stack-name $StackName `
        --region $Region `
        --query "Stacks[0].Outputs[?OutputKey=='$Key'].OutputValue | [0]" `
        --output text `
        --no-cli-pager
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($value) -or $value -eq 'None') {
        throw "No fue posible leer $Key."
    }
    return $value.Trim()
}

$identity = Get-Output 'IdentityApiBaseUrl'
$athletes = Get-Output 'AthletesApiBaseUrl'

Write-Host "Identity API: $identity"
Invoke-RestMethod -Uri "$identity/health/ready" -Method Get | ConvertTo-Json -Depth 10

Write-Host "Athletes API: $athletes"
Invoke-RestMethod -Uri "$athletes/health/ready" -Method Get | ConvertTo-Json -Depth 10

Write-Host 'Smoke publico de ambas APIs completado.'
