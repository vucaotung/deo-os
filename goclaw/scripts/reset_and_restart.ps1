#!/usr/bin/env pwsh
# Clear deo session memory + restart container to force context reload.

$ErrorActionPreference = "Continue"

Write-Host "`n=== [1/4] Show context files currently in DB for deo ===" -ForegroundColor Cyan
docker exec goclaw-postgres-1 psql -U goclaw -d goclaw -c "SELECT file_name, length(content) AS bytes, acf.updated_at FROM agent_context_files acf JOIN agents a ON a.id = acf.agent_id WHERE a.agent_key = 'deo' ORDER BY 1;"

Write-Host "`n=== [2/4] Clear deo session memory for Vincent ===" -ForegroundColor Cyan
docker exec goclaw-postgres-1 psql -U goclaw -d goclaw -c "DELETE FROM memory_chunks WHERE session_id LIKE 'agent:deo:condeobot:%' OR session_id LIKE 'deo:%'; DELETE FROM episodic_summaries WHERE session_id LIKE 'agent:deo:condeobot:%' OR session_id LIKE 'deo:%'; SELECT COUNT(*) AS remaining_memory FROM memory_chunks WHERE session_id LIKE '%deo%';"

Write-Host "`n=== [3/4] Restart goclaw container ===" -ForegroundColor Cyan
docker restart goclaw-goclaw-1
Start-Sleep -Seconds 5

Write-Host "`n=== [4/4] Re-apply credentials (post-restart) ===" -ForegroundColor Cyan
docker exec -u root goclaw-goclaw-1 sh /app/workspace/setup_credentials.sh

Write-Host "`n[DONE] Now test on Telegram with a DIFFERENT topic:" -ForegroundColor Green
Write-Host ''
Write-Host '  tao bang luong thang 6/2026 cho 2 nhan vien:' -ForegroundColor Yellow
Write-Host '  - Pham Van D, designer, 20 trieu'             -ForegroundColor Yellow
Write-Host '  - Hoang Thi E, sales, 15 trieu'               -ForegroundColor Yellow
Write-Host ''
Write-Host 'Then check logs. Expected:' -ForegroundColor Yellow
Write-Host '  promptLen larger than 26134 (AGENTS.md is now 5279 bytes)' -ForegroundColor White
Write-Host '  tool=team_tasks args contains finance-agent and office-agent' -ForegroundColor White
Write-Host '  iterations larger than 0' -ForegroundColor White
