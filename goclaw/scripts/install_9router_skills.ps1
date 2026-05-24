#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Install 9router skills (embeddings, web-fetch, image, stt, tts) into GoClaw.

.DESCRIPTION
    1. Clone 9router repo into a workspace folder (persistent)
    2. Copy 5 skill folders to /app/data/skills-store/ inside container
    3. Restart goclaw to trigger seeding
    4. Verify skills appear in DB

.NOTES
    Chỉ cài 5 skills cần thiết (bỏ '9router' overview + '9router-chat' đã có).
#>

$ErrorActionPreference = "Stop"
$skills = @(
    "9router-embeddings",
    "9router-web-fetch",
    "9router-image",
    "9router-stt",
    "9router-tts"
)

Write-Host "`n=== [1/5] Clone 9router repo (sparse, chỉ folder skills/) ===" -ForegroundColor Cyan
docker exec goclaw-goclaw-1 sh -c "rm -rf /tmp/9router && git clone --depth 1 --filter=blob:none --sparse https://github.com/decolua/9router.git /tmp/9router && cd /tmp/9router && git sparse-checkout set skills"

Write-Host "`n=== [2/5] Verify skill folders downloaded ===" -ForegroundColor Cyan
docker exec goclaw-goclaw-1 ls -la /tmp/9router/skills/

Write-Host "`n=== [3/5] Copy 5 skills to /app/data/skills-store/ ===" -ForegroundColor Cyan
foreach ($s in $skills) {
    Write-Host "  Copying $s..." -ForegroundColor White
    docker exec goclaw-goclaw-1 cp -r "/tmp/9router/skills/$s" "/app/data/skills-store/"
}

Write-Host "`n=== [4/5] Verify skills in store ===" -ForegroundColor Cyan
docker exec goclaw-goclaw-1 ls /app/data/skills-store/

Write-Host "`n=== [5/5] Restart goclaw để re-seed skills ===" -ForegroundColor Cyan
docker restart goclaw-goclaw-1
Start-Sleep -Seconds 8

Write-Host "`n=== Restore credentials sau restart ===" -ForegroundColor Cyan
docker exec -u goclaw goclaw-goclaw-1 sh -c "ls /app/.claude/backups/ | sort -r | head -1" | ForEach-Object {
    $backup = $_.Trim()
    if ($backup) {
        docker exec -u goclaw goclaw-goclaw-1 cp "/app/.claude/backups/$backup" /app/.claude.json
        Write-Host "  Restored $backup" -ForegroundColor Green
    }
}

Write-Host "`n=== Verify skills trong DB ===" -ForegroundColor Cyan
docker exec goclaw-postgres-1 psql -U goclaw -d goclaw -c "SELECT name, version FROM skills ORDER BY name;"

Write-Host "`n=== Watch startup logs (Ctrl+C khi xong) ===" -ForegroundColor Yellow
Write-Host "  docker logs goclaw-goclaw-1 --tail 50 | findstr /I 'seeded skill 9router'" -ForegroundColor White
