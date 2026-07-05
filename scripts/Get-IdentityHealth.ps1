param(
    [Parameter(Mandatory)]
    [string]$TenantId,
    [Parameter(Mandatory)]
    [string]$ClientId,
    [Parameter(Mandatory)]
    [string]$ClientSecret,
    [string]$GraphBaseUrl = "https://graph.microsoft.com"
)

# Auth to Graph
$tokenBody = @{
    grant_type    = "client_credentials"
    scope         = "$GraphBaseUrl/.default"
    client_id     = $ClientId
    client_secret = $ClientSecret
}

$token = Invoke-RestMethod -Method Post -Uri "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token" -Body $tokenBody
$headers = @{ Authorization = "Bearer $($token.access_token)" }

$result = [ordered]@{
    Timestamp          = (Get-Date).ToString("o")
    BreakGlassAccounts = @()
    AdminRoles         = @()
    MFAStatus          = @()
    RiskyUsers         = @()
    RiskySignIns       = @()
    ConditionalAccess  = @()
}

# Users (for break-glass detection)
$users = Invoke-RestMethod -Headers $headers -Uri "$GraphBaseUrl/v1.0/users" -Method Get
$result.BreakGlassAccounts = $users.value | Where-Object {
    $_.userPrincipalName -match "breakglass|emergency|admin" -and
    $_.accountEnabled -eq $true
}

# Directory roles (admin roles)
$roles = Invoke-RestMethod -Headers $headers -Uri "$GraphBaseUrl/v1.0/directoryRoles" -Method Get
$result.AdminRoles = $roles.value | Select-Object displayName, id

# MFA registration (beta endpoint)
$mfa = Invoke-RestMethod -Headers $headers -Uri "$GraphBaseUrl/beta/reports/authenticationMethods/userRegistrationDetails" -Method Get
$result.MFAStatus = $mfa.value | Select-Object userPrincipalName, isMfaCapable, isMfaRegistered

# Risky users
$riskyUsers = Invoke-RestMethod -Headers $headers -Uri "$GraphBaseUrl/v1.0/identityProtection/riskyUsers" -Method Get
$result.RiskyUsers = $riskyUsers.value

# Risky sign-ins
$riskySignIns = Invoke-RestMethod -Headers $headers -Uri "$GraphBaseUrl/v1.0/identityProtection/riskySignIns" -Method Get
$result.RiskySignIns = $riskySignIns.value

# Conditional Access policies
$caPolicies = Invoke-RestMethod -Headers $headers -Uri "$GraphBaseUrl/v1.0/identity/conditionalAccess/policies" -Method Get
$result.ConditionalAccess = $caPolicies.value

$result | ConvertTo-Json -Depth 10
