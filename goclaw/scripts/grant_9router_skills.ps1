#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Grant 9router skills tới đúng agents theo use case.

.MAPPING
    9router-embeddings → ALL agents (semantic memory cho mọi agent)
    9router-web-fetch  → deo, researcher-agent, legal-agent, crm-agent
    9router-image      → deo, marketing-agent, office-agent
    9router-stt        → deo, office-admin-agent (xử lý voice msg Telegram)
    9router-tts        → deo, office-admin-agent
#>

$ErrorActionPreference = "Stop"
$TENANT = "0193a5b0-7000-7000-8000-000000000001"

Write-Host "`n=== Current 9router skill grants (trước khi chạy) ===" -ForegroundColor Cyan
docker exec goclaw-postgres-1 psql -U goclaw -d goclaw -c "SELECT s.name AS skill, a.agent_key FROM skill_agent_grants sag JOIN skills s ON s.id=sag.skill_id JOIN agents a ON a.id=sag.agent_id WHERE s.name LIKE '9router-%' ORDER BY s.name, a.agent_key;"

$sql = @"
-- 1. Embeddings: grant cho mọi agent (semantic memory phổ quát)
INSERT INTO skill_agent_grants (skill_id, agent_id, pinned_version, granted_by, tenant_id)
SELECT s.id, a.id, 1, 'admin', '$TENANT'
FROM skills s CROSS JOIN agents a
WHERE s.name = '9router-embeddings'
ON CONFLICT (skill_id, agent_id) DO NOTHING;

-- 2. Web fetch: chỉ research/legal/crm/deo
INSERT INTO skill_agent_grants (skill_id, agent_id, pinned_version, granted_by, tenant_id)
SELECT s.id, a.id, 1, 'admin', '$TENANT'
FROM skills s CROSS JOIN agents a
WHERE s.name = '9router-web-fetch'
  AND a.agent_key IN ('deo', 'researcher-agent', 'legal-agent', 'crm-agent', 'marketing-agent')
ON CONFLICT (skill_id, agent_id) DO NOTHING;

-- 3. Image generation: marketing + office + deo
INSERT INTO skill_agent_grants (skill_id, agent_id, pinned_version, granted_by, tenant_id)
SELECT s.id, a.id, 1, 'admin', '$TENANT'
FROM skills s CROSS JOIN agents a
WHERE s.name = '9router-image'
  AND a.agent_key IN ('deo', 'marketing-agent', 'office-agent')
ON CONFLICT (skill_id, agent_id) DO NOTHING;

-- 4. STT: deo + office-admin (xử lý voice msg Telegram)
INSERT INTO skill_agent_grants (skill_id, agent_id, pinned_version, granted_by, tenant_id)
SELECT s.id, a.id, 1, 'admin', '$TENANT'
FROM skills s CROSS JOIN agents a
WHERE s.name = '9router-stt'
  AND a.agent_key IN ('deo', 'office-admin-agent')
ON CONFLICT (skill_id, agent_id) DO NOTHING;

-- 5. TTS: deo + office-admin (gửi voice reply Telegram)
INSERT INTO skill_agent_grants (skill_id, agent_id, pinned_version, granted_by, tenant_id)
SELECT s.id, a.id, 1, 'admin', '$TENANT'
FROM skills s CROSS JOIN agents a
WHERE s.name = '9router-tts'
  AND a.agent_key IN ('deo', 'office-admin-agent')
ON CONFLICT (skill_id, agent_id) DO NOTHING;
"@

Write-Host "`n=== Applying grants ===" -ForegroundColor Cyan
docker exec goclaw-postgres-1 psql -U goclaw -d goclaw -c $sql

Write-Host "`n=== New grants (sau khi chạy) ===" -ForegroundColor Cyan
docker exec goclaw-postgres-1 psql -U goclaw -d goclaw -c "SELECT s.name AS skill, a.agent_key FROM skill_agent_grants sag JOIN skills s ON s.id=sag.skill_id JOIN agents a ON a.id=sag.agent_id WHERE s.name LIKE '9router-%' ORDER BY s.name, a.agent_key;"

Write-Host "`n=== Summary count per skill ===" -ForegroundColor Cyan
docker exec goclaw-postgres-1 psql -U goclaw -d goclaw -c "SELECT s.name AS skill, COUNT(sag.agent_id) AS agents_granted FROM skills s LEFT JOIN skill_agent_grants sag ON sag.skill_id=s.id WHERE s.name LIKE '9router-%' GROUP BY s.name ORDER BY s.name;"

Write-Host "`nDone." -ForegroundColor Green
Write-Host "Restart goclaw để pickup grants:" -ForegroundColor Yellow
Write-Host "  docker restart goclaw-goclaw-1" -ForegroundColor White
