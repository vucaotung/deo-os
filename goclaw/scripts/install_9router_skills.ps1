#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Install 5 9router skills into GoClaw skills-store.

.DESCRIPTION
    Container không có `git` nên download tarball từ GitHub bằng PowerShell,
    extract trên workstation, rồi `docker cp` vào container.
#>

$ErrorActionPreference = "Stop"
$skills = @("9router-embeddings", "9router-web-fetch", "9router-image", "9router-stt", "9router-tts")
$tmp = "C:\Temp\9router-skills"
$tarUrl = "https://github.com/decolua/9router/archive/refs/heads/master.tar.gz"

Write-Host "`n=== [1/6] Cleanup + download tarball ===" -ForegroundColor Cyan
if (Test-Path $tmp) { Remove-Item -Recurse -Force $tmp }
New-Item -ItemType Directory -Force -Path $tmp | Out-Null

$tarPath = "$tmp\9router.tar.gz"
Invoke-WebRequest -Uri $tarUrl -OutFile $tarPath -UseBasicParsing
Write-Host "  Downloaded $(Get-Item $tarPath | Select-Object -ExpandProperty Length) bytes" -ForegroundColor White

Write-Host "`n=== [2/6] Extract tarball ===" -ForegroundColor Cyan
# tar có sẵn trên Win10+ (1803+)
tar -xzf $tarPath -C $tmp
$extracted = Get-ChildItem $tmp -Directory | Where-Object { $_.Name -like "9router-*" } | Select-Object -First 1
Write-Host "  Extracted to: $($extracted.FullName)" -ForegroundColor White

Write-Host "`n=== [3/6] Verify skill folders exist ===" -ForegroundColor Cyan
foreach ($s in $skills) {
    $path = Join-Path $extracted.FullName "skills\$s"
    if (Test-Path $path) {
        $files = (Get-ChildItem $path -Recurse -File).Count
        Write-Host "  OK $s ($files files)" -ForegroundColor Green
    } else {
        Write-Host "  MISSING $s" -ForegroundColor Red
    }
}

Write-Host "`n=== [4/6] Copy skills into container /app/data/skills-store/ ===" -ForegroundColor Cyan
foreach ($s in $skills) {
    $src = Join-Path $extracted.FullName "skills\$s"
    if (Test-Path $src) {
        Write-Host "  docker cp $s ..." -ForegroundColor White
        docker cp "$src" "goclaw-goclaw-1:/app/data/skills-store/"
        # Fix ownership
        docker exec -u root goclaw-goclaw-1 chown -R goclaw:goclaw "/app/data/skills-store/$s"
    }
}

Write-Host "`n=== [5/6] Verify skills trong container ===" -ForegroundColor Cyan
docker exec goclaw-goclaw-1 ls -la /app/data/skills-store/

Write-Host "`n=== [6/6] Restart goclaw + restore credentials ===" -ForegroundColor Cyan
docker restart goclaw-goclaw-1
Start-Sleep -Seconds 8

# Restore .claude.json
$backupName = docker exec -u goclaw goclaw-goclaw-1 sh -c "ls /app/.claude/backups/ 2>/dev/null | tail -1"
if ($backupName) {
    $backup = $backupName.Trim()
    docker exec -u goclaw goclaw-goclaw-1 cp "/app/.claude/backups/$backup" /app/.claude.json
    Write-Host "  Restored: $backup" -ForegroundColor Green
}

Write-Host "`n=== Skills in DB sau seed ===" -ForegroundColor Cyan
docker exec goclaw-postgres-1 psql -U goclaw -d goclaw -c "SELECT name, version FROM skills ORDER BY name;"

Write-Host "`n=== Startup logs - tim 9router seeded ===" -ForegroundColor Cyan
docker logs goclaw-goclaw-1 --tail 100 | Select-String -Pattern "seeder|skill_search|9router" -CaseSensitive:$false
