param (
    [Parameter(Mandatory=$false)]
    [string]$WebhookUrl = $env:SLACK_WEBHOOK_URL,

    [Parameter(Mandatory=$false)]
    [string]$Status = "SUCCESS",

    [Parameter(Mandatory=$false)]
    [string]$Details = "All security gates passed successfully."
)

if (-not $WebhookUrl) {
    Write-Warning "SLACK_WEBHOOK_URL environment variable is not defined. Skipping Slack notification."
    exit 0
}

$color = if ($Status -eq "SUCCESS") { "#36a64f" } else { "#e01e5a" }
$icon = if ($Status -eq "SUCCESS") { "🛡️" } else { "⚠️" }

$payload = @{
    attachments = @(
        @{
            color = $color
            blocks = @(
                @{
                    type = "header"
                    text = @{
                        type = "plain_text"
                        text = "$icon DevSecOps Pipeline Status: $Status"
                    }
                },
                @{
                    type = "section"
                    text = @{
                        type = "mrkdwn"
                        text = "*Execution Details:*\n$Details"
                    }
                },
                @{
                    type = "context"
                    elements = @(
                        @{
                            type = "mrkdwn"
                            text = "Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss UTC') | Host: $env:COMPUTERNAME"
                        }
                    )
                }
            )
        }
    )
} | ConvertTo-Json -Depth 5

try {
    $response = Invoke-RestMethod -Uri $WebhookUrl -Method Post -Body $payload -ContentType 'application/json'
    Write-Host "Slack notification sent successfully." -ForegroundColor Green
} catch {
    Write-Error "Failed to dispatch Slack notification: $_"
}
