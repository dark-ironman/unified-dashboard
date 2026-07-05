param(
    [Parameter(Mandatory)]
    [string]$WebhookUrl,
    [Parameter(Mandatory)]
    [string]$Title,
    [Parameter(Mandatory)]
    [string]$Message,
    [ValidateSet("Info","Warning","Critical")]
    [string]$Severity = "Info"
)

$color = switch ($Severity) {
    "Critical" { "FF0000" }
    "Warning"  { "FFA500" }
    default    { "0078D4" }
}

$payload = @{
    "@type"      = "MessageCard"
    "@context"   = "http://schema.org/extensions"
    "themeColor" = $color
    "summary"    = $Title
    "sections"   = @(
        @{
            "activityTitle" = $Title
            "text"          = $Message
        }
    )
}

Invoke-RestMethod -Method Post -Uri $WebhookUrl -Body ($payload | ConvertTo-Json -Depth 10) -ContentType "application/json"
