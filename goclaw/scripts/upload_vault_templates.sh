#!/usr/bin/env bash
# Upload vault templates to GoClaw Vault via API.
# Run from Win10 workstation (has route to GoClaw gateway).
#
# Required env:
#   GOCLAW_URL   default http://localhost:18790
#   GOCLAW_TOKEN gateway bearer token

set -euo pipefail

GOCLAW_URL="${GOCLAW_URL:-http://localhost:18790}"
TOKEN="${GOCLAW_TOKEN:?Set GOCLAW_TOKEN=<bearer>}"
AGENT="${AGENT:-deo}"

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
VAULT_DIR="$REPO_ROOT/goclaw/vault"

upload() {
    local title="$1" path="$2" tags="$3"
    local content
    content="$(jq -Rs . < "$path")"
    local payload
    payload="$(jq -n \
        --arg title "$title" \
        --argjson content "$content" \
        --argjson tags "$tags" \
        '{title: $title, content: $content, tags: $tags}')"
    echo ">> $title"
    curl -sS -X POST "$GOCLAW_URL/v1/agents/$AGENT/vault/documents" \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d "$payload" | jq .
}

upload "Template Bảng Lương" \
    "$VAULT_DIR/02_templates/ke-toan/bang-luong.md" \
    '["template","ke-toan","bang-luong"]'

upload "Template Hợp Đồng Lao Động" \
    "$VAULT_DIR/02_templates/legal/hop-dong-lao-dong.md" \
    '["template","legal","hdld"]'

upload "Template Đơn Xin Nghỉ Phép" \
    "$VAULT_DIR/02_templates/hr/don-xin-nghi-phep.md" \
    '["template","hr","nghi-phep"]'

upload "Company Info" \
    "$VAULT_DIR/01_company/company-info.md" \
    '["company","master-data"]'

echo "Done."
