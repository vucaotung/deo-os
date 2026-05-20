# Dẹo Enterprise OS — Operations Cheatsheet

> Quick-reference cho các lệnh hay dùng trên Xeon Win10 workstation.
> Cập nhật lần cuối: 2026-05-20 (v0.3.0)

---

## 1. Container & Compose

```powershell
# Recreate với input bind mount
cd C:\goclaw
docker compose -f docker-compose.yml -f docker-compose.postgres.yml -f docker-compose.override.yml up -d

# Restart goclaw (clear in-memory context cache)
docker restart goclaw-goclaw-1

# Container names
# - goclaw-goclaw-1     (gateway + agent runtime)
# - goclaw-postgres-1   (PostgreSQL)
# - deo-postgres        (separate, không dùng cho GoClaw)

# Logs realtime
docker logs goclaw-goclaw-1 --tail 80 -f

# Logs filter
docker logs goclaw-goclaw-1 --tail 200 | findstr /R "agent= tool= team_tasks vault gdrive"
```

## 2. PostgreSQL

**DSN (host):** `postgresql://goclaw:goclaw@localhost:5432/goclaw`

**Hostname inside container:** Postgres ở container riêng → KHÔNG dùng `localhost` từ trong goclaw-goclaw-1. Chạy `psql` trong `goclaw-postgres-1`:

```powershell
docker exec goclaw-postgres-1 psql -U goclaw -d goclaw -c "<SQL>"
```

**Common queries:**

```sql
-- List tables
\dt

-- Agents
SELECT agent_key, id, provider, model FROM agents ORDER BY agent_key;

-- Tenants
SELECT id, name FROM tenants;
-- Master tenant: 0193a5b0-7000-7000-8000-000000000001

-- Users
SELECT user_id, display_name, role FROM tenant_users;
-- Vincent: user_id='7293498822' (Telegram ID string)

-- Agent context files (per-agent, scoped to tenant)
SELECT a.agent_key, acf.file_name, length(acf.content) AS bytes, acf.updated_at
FROM agent_context_files acf
JOIN agents a ON a.id = acf.agent_id
WHERE a.agent_key = 'deo'
ORDER BY 1, 2;

-- User context files (per-agent + per-user)
SELECT a.agent_key, ucf.user_id, ucf.file_name
FROM user_context_files ucf
JOIN agents a ON a.id = ucf.agent_id
WHERE ucf.user_id = '7293498822';

-- Vault documents
SELECT path, title, scope FROM vault_documents WHERE scope = 'shared';

-- Recent team tasks
SELECT id, title, assignee, status, created_at FROM team_tasks ORDER BY created_at DESC LIMIT 10;
```

## 3. DB Schemas (đáng nhớ)

| Table | Key cols | Notes |
|-------|----------|-------|
| `agents` | id (uuid), agent_key, provider, model | provider có thể: claude, openai-codex, openrouter... |
| `tenants` | id (uuid), name | "Master" tenant cố định |
| `tenant_users` | user_id (varchar), tenant_id, role | user_id = Telegram ID string |
| `agent_context_files` | agent_id, file_name, content, **tenant_id** | UNIQUE(agent_id, file_name); KHÔNG có user_id/scope cột |
| `user_context_files` | agent_id, user_id, file_name, content, tenant_id | UNIQUE(agent_id, user_id, file_name); per-user context |
| `vault_documents` | tenant_id, scope, path, title, content_hash, summary | scope = personal/team/shared/custom |
| `vault_versions` | doc_id, version, content | content nằm ở đây, không phải trong `vault_documents` |

## 4. Sync Context Files từ Git → DB

```powershell
cd C:\deo-os
git pull
$env:DSN = "postgresql://goclaw:goclaw@localhost:5432/goclaw"

# All agents (dry-run first)
python goclaw\scripts\sync_context_files.py --dry-run
python goclaw\scripts\sync_context_files.py

# Single agent
python goclaw\scripts\sync_context_files.py --agent deo

# Include vault templates
python goclaw\scripts\sync_context_files.py --vault
```

Source files trong repo:
- `goclaw/agents/<agent_key>/{SOUL,IDENTITY,AGENTS,CAPABILITIES,TOOLS}.md`
- `goclaw/users/vincent_USER.md` → applied to `deo` + `office-admin-agent`
- `goclaw/vault/{01_company,02_templates/*}/*.md`

## 5. One-shot scripts

```powershell
# Full deploy (pull + sync + verify)
.\goclaw\scripts\deploy.ps1

# Reset session memory + restart container (bust context cache)
.\goclaw\scripts\reset_and_restart.ps1
```

## 6. Claude CLI / Credentials

Sau mỗi lần restart container, có thể bị mất `.claude.json`:

```powershell
# Restore from backup
docker exec -u goclaw goclaw-goclaw-1 cp /app/.claude/backups/.claude.json.backup.1778767180381 /app/.claude.json

# Verify
docker exec -u goclaw goclaw-goclaw-1 claude auth status
# Expected: "loggedIn": true, "subscriptionType": "pro"
```

Nếu `.credentials.json` bị lock (cp fail "File exists"):

```powershell
docker exec -u root goclaw-goclaw-1 sh -c "rm -f /app/.claude/.credentials.json && cp /app/workspace/.claude/.credentials.json /app/.claude/ && chown goclaw:goclaw /app/.claude/.credentials.json && chmod 600 /app/.claude/.credentials.json"
```

## 7. Post-recreate persistence

Sau `docker compose up` với recreate, tools và credentials cần re-install:

```powershell
docker exec -u root goclaw-goclaw-1 sh /app/workspace/setup_all_tools.sh
docker exec -u root goclaw-goclaw-1 sh /app/workspace/setup_credentials.sh
```

Scripts persistent trong workspace volume `goclaw_goclaw-workspace`.

## 8. Bind mounts & paths

| Logical | Physical | Notes |
|---------|----------|-------|
| Input | `C:\deo-inputs\` → `/app/workspace/05_INPUTS/` | Human drops files |
| Workspace | Docker volume → `/app/workspace/` | Agent WIP + scripts |
| Vault | DB (`vault_documents` + `vault_versions`) | Không phải filesystem |
| Output | `/app/workspace/04_OUTPUTS/` → Drive | `gdrive-upload.sh` |
| Claude home | `/app/.claude/` | Credentials + projects |
| GoClaw user HOME | `/app/` (KHÔNG phải `/home/goclaw`) | |

## 9. Google Drive upload

```powershell
# From workstation
docker exec goclaw-goclaw-1 sh /app/workspace/gdrive-upload.sh <local_path> <drive_subfolder>

# Inside container (agent gọi tự động qua custom tool gdrive_upload)
sh /app/workspace/gdrive-upload.sh /app/workspace/04_OUTPUTS/file.xlsx finance/
```

Trả về Drive shareable link.

## 10. GoClaw Gateway API

```powershell
$token = "13b2146048b3e88b29fdd16764098ba2469fdcbfb71772793c37d7a0807a7442"
$url = "http://localhost:18790"   # hoặc Tailscale 100.90.129.11:18790

# Health
curl $url/health

# Agent list (qua web UI: open http://localhost:18790)
```

## 11. Telegram

- Bot: `@condeobot` → routes to `deo` agent
- Bot: `@agent_admin_deo_bot` → routes to `office-admin-agent`
- Owner Vincent: `7293498822`

## 12. Debug context loading

Khi `promptLen` không đổi sau khi sync AGENTS.md:

1. **Verify DB content**:
   ```powershell
   docker exec goclaw-postgres-1 psql -U goclaw -d goclaw -c "SELECT file_name, length(content), updated_at FROM agent_context_files acf JOIN agents a ON a.id=acf.agent_id WHERE a.agent_key='deo';"
   ```

2. **Restart container** để clear in-memory cache:
   ```powershell
   docker restart goclaw-goclaw-1
   ```

3. **Reset session** (tránh "đã làm rồi" memory):
   - Gửi tin nhắn với topic MỚI trên Telegram (tháng/người khác)
   - Hoặc `/reset` nếu bot hỗ trợ

4. **Check logs** sau khi gửi tin nhắn mới:
   ```powershell
   docker logs goclaw-goclaw-1 --tail 60
   ```
   Tìm `promptLen=` và so sánh với baseline.

## 13. Known issues / Workarounds

| Issue | Fix |
|-------|-----|
| `psql localhost connection refused` from inside goclaw container | Chạy psql trong `goclaw-postgres-1` thay vì `goclaw-goclaw-1` |
| `relation "users" does not exist` | Dùng `tenant_users`, không phải `users` |
| `column "session_id" does not exist` in memory_chunks | Schema khác mong đợi — check `\d memory_chunks` trước |
| `cp: can't create credentials.json: File exists` | `rm -f` trước rồi mới cp |
| `loggedIn: false` sau restart | Restore `/app/.claude.json` từ backup |
| `promptLen` không thay đổi sau sync | Restart container; check cache layer |
| Em-dash `—` trong PowerShell `Write-Host` | Dùng ASCII `--` hoặc single quote `'...'` |
| `>` trong PowerShell double-quote string | Dùng single quote `'...'` |
| deo tự dùng `use_skill(xlsx)` bỏ qua finance-agent | Routing rules đã được inject vào SOUL.md (top) + USER_PREDEFINED.md; chạy deploy.ps1 + restart container |
| `promptLen` không tăng sau thêm AGENTS.md | Prompt budget đã đầy; routing rules chuyển sang SOUL.md đầu file + USER_PREDEFINED.md ngắn gọn |
| deo vẫn gọi "Sếp" thay vì "anh Tung" | SOUL.md đã có RULE 3 ở đầu file; sync + restart container |

## 14. Provider hiện tại (production state)

```sql
SELECT agent_key, provider, model FROM agents;
```

Tại 2026-05-20:
- `deo`: `openai-codex` / `gpt-5.4` (KHÔNG phải `claude-cli` như CHANGELOG v0.2.0)
- Các agent khác: kiểm tra theo từng case

Để đổi provider:
```sql
UPDATE agents SET provider='claude', model='claude-sonnet' WHERE agent_key='deo';
```

## 15. Vault upload (bypass API)

API `/v1/agents/{id}/vault/documents` có thể không tồn tại — dùng DB direct (qua `sync_context_files.py --vault`) hoặc copy file vào workspace:

```powershell
docker exec goclaw-goclaw-1 mkdir -p /app/workspace/02_VAULT/02_templates/ke-toan
docker cp C:\deo-os\goclaw\vault\02_templates\ke-toan\bang-luong.md goclaw-goclaw-1:/app/workspace/02_VAULT/02_templates/ke-toan/
```

## 16. PR workflow

```powershell
# Current branch
git branch --show-current

# Create draft PR
gh pr create --draft --title "..." --body "..."
# Hoặc dùng MCP github tool từ Claude Code

# View PR
gh pr view <PR#>
```

PR hiện tại: https://github.com/vucaotung/deo-os/pull/1 (Phase 1)

---

## Phụ lục — Hằng số

| Tên | Value |
|-----|-------|
| `TENANT_ID` (Master) | `0193a5b0-7000-7000-8000-000000000001` |
| `VINCENT_USER_ID` | `7293498822` |
| GoClaw bearer token | `13b2146048b3e88b29fdd16764098ba2469fdcbfb71772793c37d7a0807a7442` |
| Gateway port | `18790` |
| Postgres port | `5432` |
| Tailscale IP | `100.90.129.11` |
| Container goclaw | `goclaw-goclaw-1` |
| Container postgres | `goclaw-postgres-1` |
