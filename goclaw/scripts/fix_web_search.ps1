#!/usr/bin/env pwsh
# Disable exa (no API key), prefer tavily + brave (keys already in config_secrets).
# Required after v3.12.0 upgrade — default provider_order has exa first which fails.

$ErrorActionPreference = "Stop"
$TENANT = "0193a5b0-7000-7000-8000-000000000001"

$sql = @"
INSERT INTO builtin_tool_tenant_configs (tool_name, tenant_id, enabled, settings)
VALUES ('web_search', '$TENANT', true,
'{"exa": {"enabled": false}, "tavily": {"enabled": true}, "brave": {"enabled": true}, "duckduckgo": {"enabled": true}, "provider_order": ["tavily", "brave", "duckduckgo"]}'::jsonb)
ON CONFLICT (tool_name, tenant_id)
DO UPDATE SET settings = EXCLUDED.settings, enabled = EXCLUDED.enabled, updated_at = NOW();
"@

Write-Host "Applying web_search override (disable exa, prefer tavily+brave)..." -ForegroundColor Cyan
docker exec goclaw-postgres-1 psql -U goclaw -d goclaw -c $sql

Write-Host "`nVerify:" -ForegroundColor Cyan
docker exec goclaw-postgres-1 psql -U goclaw -d goclaw -c "SELECT tool_name, enabled, settings FROM builtin_tool_tenant_configs WHERE tool_name='web_search';"

Write-Host "`nDone. Restart goclaw để pickup config:" -ForegroundColor Green
Write-Host "  docker restart goclaw-goclaw-1" -ForegroundColor Yellow
