param(
    [Parameter(Mandatory)]
    [string]$TenantId,
    [Parameter(Mandatory)]
    [string]$ClientId,
    [Parameter(Mandatory)]
    [string]$ClientSecret,
    [string]$DefenderBaseUrl = "https://api.security.microsoft.com"
)

# Auth to Defender
$tokenBody = @{
    grant_type    = "client_credentials"
    scope         = "$DefenderBaseUrl/.default"
    client_id     = $ClientId
    client_secret = $ClientSecret
}

$token = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" -Body $tokenBody
$headers = @{ Authorization = "Bearer $($token.access_token)" }

$result = [ordered]@{
    Timestamp      = (Get-Date).ToString("o")
    ExposureScore  = $null
    SecureScore    = $null
    Devices        = @()
    Vulnerabilities = @()
}

# Exposure score
try {
    $exposure = Invoke-RestMethod -Headers $headers -Uri "$DefenderBaseUrl/api/exposureScore" -Method Get
    $result.ExposureScore = $exposure
} catch { }

# Secure score
try {
    $secure = Invoke-RestMethod -Headers $headers -Uri "$DefenderBaseUrl/api/secureScore" -Method Get
    $result.SecureScore = $secure
} catch { }

# Devices
try {
    $devices = Invoke-RestMethod -Headers $headers -Uri "$DefenderBaseUrl/api/machines" -Method Get
    $result.Devices = $devices.value
} catch { }

# Vulnerabilities
try {
    $vulns = Invoke-RestMethod -Headers $headers -Uri "$DefenderBaseUrl/api/vulnerabilities" -Method Get
    $result.Vulnerabilities = $vulns.value
} catch { }

$result | ConvertTo-Json -Depth 10
