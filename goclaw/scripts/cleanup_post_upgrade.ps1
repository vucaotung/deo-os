#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Cleanup post-v3.12.0 upgrade — disable dead OAuth providers + fix consolidation pipeline.

.DESCRIPTION
    Logs đang spam 2 loại error:
    1. "oauth token refresh failed ... refresh_token_reused" cho 4 chatgpt_oauth providers
    2. "episodic: summarize: HTTP 404: 9router: No active credentials for provider: gemini"

    Fix:
    - Disable 4 dead OAuth providers (enabled=false)
    - Đổi consolidation/background provider sang 9router với model claude-sonnet-4-6
#>

$ErrorActionPreference = "Stop"

Write-Host "`n=== [1/4] Disable dead OAuth providers ===" -ForegroundColor Cyan
docker exec goclaw-postgres-1 psql -U goclaw -d goclaw -c "UPDATE llm_providers SET enabled=false WHERE name IN ('openai-codex', 'openai-codex1', 'openai-codex-2', '3-enterpriseos-bond');"
docker exec goclaw-postgres-1 psql -U goclaw -d goclaw -c "SELECT name, provider_type, enabled FROM llm_providers ORDER BY enabled DESC, name;"

Write-Host "`n=== [2/4] Fix consolidation pipeline (was: 9router/Gemini, no creds) ===" -ForegroundColor Cyan
docker exec goclaw-postgres-1 psql -U goclaw -d goclaw -c "UPDATE system_configs SET value='9router' WHERE key='background.provider';"
docker exec goclaw-postgres-1 psql -U goclaw -d goclaw -c "UPDATE system_configs SET value='cc/claude-sonnet-4-6' WHERE key='background.model';"
docker exec goclaw-postgres-1 psql -U goclaw -d goclaw -c "SELECT key, value FROM system_configs WHERE key LIKE 'background%';"

Write-Host "`n=== [3/4] Restart container ===" -ForegroundColor Cyan
docker restart goclaw-goclaw-1
Start-Sleep -Seconds 8

# Restore credentials
$backupName = docker exec -u goclaw goclaw-goclaw-1 sh -c "ls /app/.claude/backups/ 2>/dev/null | tail -1"
if ($backupName) {
    docker exec -u goclaw goclaw-goclaw-1 cp "/app/.claude/backups/$($backupName.Trim())" /app/.claude.json
}

Write-Host "`n=== [4/4] Verify - tim warn/error trong 50 dong cuoi ===" -ForegroundColor Cyan
docker logs goclaw-goclaw-1 --tail 80 | Select-String -Pattern "warn|error|oauth|gemini|consolidation" -CaseSensitive:$false

Write-Host "`nDone." -ForegroundColor Green
