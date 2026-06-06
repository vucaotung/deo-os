#!/usr/bin/env pwsh
<#
.SYNOPSIS
    All-in-one deploy: pull code → sync context → verify → output next steps.
.USAGE
    .\goclaw\scripts\deploy.ps1
#>

$ErrorActionPreference = "Stop"
$repo = "C:\deo-os"
$dsn  = "postgresql://goclaw:goclaw@localhost:5432/goclaw"

Write-Host "`n=== [1/5] Pulling latest code ===" -ForegroundColor Cyan
Set-Location $repo
git pull

Write-Host "`n=== [2/5] Showing what files exist in goclaw/agents/deo/ ===" -ForegroundColor Cyan
Get-ChildItem goclaw\agents\deo\ | Select-Object Name, Length, LastWriteTime

Write-Host "`n=== [3/5] Syncing all agent context files to DB ===" -ForegroundColor Cyan
$env:DSN = $dsn
python goclaw\scripts\sync_context_files.py

Write-Host "`n=== [4/5] Verifying deo context in DB ===" -ForegroundColor Cyan
docker exec goclaw-postgres-1 psql -U goclaw -d goclaw -c @"
SELECT file_name, length(content) AS bytes, updated_at
FROM agent_context_files acf
JOIN agents a ON a.id = acf.agent_id
WHERE a.agent_key = 'deo'
ORDER BY 1;
"@

Write-Host "`n=== [5/5] Done ===" -ForegroundColor Green
Write-Host ""
Write-Host "Now test on Telegram @condeobot:" -ForegroundColor Yellow
Write-Host "  tao bang luong thang 5/2026 voi 3 nhan vien test:" -ForegroundColor White
Write-Host "  - Nguyen Van A, dev, 25 trieu"  -ForegroundColor White
Write-Host "  - Tran Thi B, ke toan, 18 trieu" -ForegroundColor White
Write-Host "  - Le Van C, intern, 8 trieu"     -ForegroundColor White
Write-Host ""
Write-Host "Then watch logs:" -ForegroundColor Yellow
Write-Host "  docker logs goclaw-goclaw-1 --tail 80 -f" -ForegroundColor White
Write-Host ""
Write-Host "Expected: tool=team_tasks (not use_skill); promptLen > 26134" -ForegroundColor Yellow
