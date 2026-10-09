#!/usr/bin/env bash
set -euo pipefail

# ==============================================================================
# DevSecOps Pipeline Slack Webhook Notification Script
# ==============================================================================

WEBHOOK_URL="${1:-${SLACK_WEBHOOK_URL:-}}"
STATUS="${2:-SUCCESS}"
DETAILS="${3:-All security gates passed successfully.}"

if [ -z "$WEBHOOK_URL" ]; then
  echo "[WARN] SLACK_WEBHOOK_URL is not set. Skipping Slack notification."
  exit 0
fi

COLOR="#36a64f"
ICON="🛡️"
if [ "$STATUS" != "SUCCESS" ]; then
  COLOR="#e01e5a"
  ICON="⚠️"
fi

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

PAYLOAD=$(cat <<EOF
{
  "attachments": [
    {
      "color": "${COLOR}",
      "blocks": [
        {
          "type": "header",
          "text": {
            "type": "plain_text",
            "text": "${ICON} DevSecOps Pipeline Alert: ${STATUS}"
          }
        },
        {
          "type": "section",
          "text": {
            "type": "mrkdwn",
            "text": "*Status:* \`${STATUS}\`\n*Details:* ${DETAILS}"
          }
        },
        {
          "type": "context",
          "elements": [
            {
              "type": "mrkdwn",
              "text": "Audit Timestamp: ${TIMESTAMP} | Host: $(hostname)"
            }
          ]
        }
      ]
    }
  ]
}
EOF
)

curl -s -X POST -H 'Content-type: application/json' --data "${PAYLOAD}" "${WEBHOOK_URL}" > /dev/null
echo "[INFO] Slack notification dispatched successfully."
