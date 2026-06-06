#!/usr/bin/env pwsh
# Setup skill grants so only office-agent (and finance/legal/hr agents for fallback)
# can use xlsx/docx/pptx/pdf skills. Force deo to delegate.
#
# Run AFTER upgrade to v3.12.0. Test with deo trên Telegram - nếu deo bị block
# use_skill() và delegate đúng qua team_tasks → success.

$ErrorActionPreference = "Stop"
$TENANT = "0193a5b0-7000-7000-8000-000000000001"

Write-Host "=== Current grants ===" -ForegroundColor Cyan
docker exec goclaw-postgres-1 psql -U goclaw -d goclaw -c "SELECT s.name AS skill, a.agent_key FROM skill_agent_grants sag JOIN skills s ON s.id=sag.skill_id JOIN agents a ON a.id=sag.agent_id ORDER BY a.agent_key, s.name;"

$sql = @"
-- Grant xlsx/docx/pptx/pdf/xu-ly-van-phong to office-agent (primary file producer)
INSERT INTO skill_agent_grants (skill_id, agent_id, pinned_version, granted_by, tenant_id)
SELECT s.id, a.id, 1, 'admin', '$TENANT'
FROM skills s
CROSS JOIN agents a
WHERE a.agent_key = 'office-agent'
  AND s.name IN ('xlsx', 'docx', 'pptx', 'pdf', 'xu-ly-van-phong')
ON CONFLICT (skill_id, agent_id) DO NOTHING;

-- Grant skill-creator to dev/admin agents (creators only)
INSERT INTO skill_agent_grants (skill_id, agent_id, pinned_version, granted_by, tenant_id)
SELECT s.id, a.id, 1, 'admin', '$TENANT'
FROM skills s
CROSS JOIN agents a
WHERE a.agent_key IN ('it-dev-agent', 'office-admin-agent')
  AND s.name = 'skill-creator'
ON CONFLICT (skill_id, agent_id) DO NOTHING;
"@

Write-Host "`n=== Applying grants ===" -ForegroundColor Cyan
docker exec goclaw-postgres-1 psql -U goclaw -d goclaw -c $sql

Write-Host "`n=== New grants ===" -ForegroundColor Cyan
docker exec goclaw-postgres-1 psql -U goclaw -d goclaw -c "SELECT s.name AS skill, a.agent_key FROM skill_agent_grants sag JOIN skills s ON s.id=sag.skill_id JOIN agents a ON a.id=sag.agent_id ORDER BY a.agent_key, s.name;"

Write-Host "`nDone." -ForegroundColor Green
Write-Host "Test trên Telegram @condeobot:" -ForegroundColor Yellow
Write-Host "  tao bang luong thang 6 cho 2 nhan vien: A 20tr, B 15tr" -ForegroundColor White
Write-Host ""
Write-Host "Expected: deo KHONG dung use_skill(xlsx), buoc delegate qua team_tasks(finance-agent + office-agent)" -ForegroundColor White
