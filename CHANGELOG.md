# Changelog

## [0.3.0] - 2026-05-20

### Added — Phase 1 continuation

**L2 Agent context files (Vietnamese, role-specific)** in `goclaw/agents/`:
- `finance-agent/` — SOUL, IDENTITY, AGENTS, CAPABILITIES (kế toán VN, biểu thuế TNCN 7 bậc, BHXH 10.5%/21.5%, GTGT 8/10%)
- `legal-agent/` — pháp chế VN, dẫn BLLĐ 2019, Luật DN 2020, BLDS 2015
- `hr-agent/` — onboarding/offboarding, phép theo Điều 113 BLLĐ, kỷ luật theo Điều 122/125
- `crm-agent/` — 10 pipeline stages, BANT/MEDDIC, weighted forecast, follow-up cadence

**Vault templates** in `goclaw/vault/`:
- `02_templates/ke-toan/bang-luong.md` — template bảng lương VN với BHXH/TNCN
- `02_templates/legal/hop-dong-lao-dong.md` — mẫu HĐLĐ theo BLLĐ 2019
- `02_templates/hr/don-xin-nghi-phep.md` — mẫu đơn nghỉ phép
- `01_company/company-info.md` — master-data công ty (placeholder để owner điền)

**Per-user context** in `goclaw/users/`:
- `vincent_USER.md` — identity, preferences, authority cho Vincent (Telegram 7293498822)

**Sync tooling** in `goclaw/scripts/`:
- `sync_context_files.py` — đẩy agent + user context files + vault docs từ git vào DB
  - Hỗ trợ `--dry-run`, `--agent KEY`, `--vault`
  - Đúng schema: `agent_context_files` (tenant_id required), `user_context_files` (per-user), `vault_documents`+`vault_versions`
- `upload_vault_templates.sh` — alternative upload via Vault API
- `deploy.ps1` — one-shot: pull → sync → verify
- `reset_and_restart.ps1` — clear session memory + restart container (bust context cache)

**Hardened deo routing** (`goclaw/agents/deo/`):
- `AGENTS.md` (5.3 KB) — explicit ROUTING TABLE (keyword → L2 agent), hard rules forbidding `use_skill(xlsx)`, `write_file`, `exec` for output files; approval gate for high-stakes actions
- `SOUL.md` — strengthened COO framing, "anh Tung" instead of "Sếp", explicit don'ts

**Docs**:
- `docs/CHEATSHEET.md` — 16-section operational reference: containers, Postgres, schemas, sync workflow, credentials recovery, debug guide, known issues + fixes

### Deployment notes (chạy từ Win10 workstation)

```bash
# 1. Apply context files vào DB
DSN=postgresql://goclaw:goclaw@localhost:5432/goclaw \
  python3 goclaw/scripts/sync_context_files.py --dry-run
DSN=... python3 goclaw/scripts/sync_context_files.py

# 2. Upload vault templates
GOCLAW_TOKEN=<bearer> bash goclaw/scripts/upload_vault_templates.sh

# 3. Input bind mount
mkdir C:\deo-inputs
cp infrastructure/docker/docker-compose.override.yml C:\goclaw\
cd C:\goclaw
docker compose -f docker-compose.yml -f docker-compose.postgres.yml -f docker-compose.override.yml up -d
```

### Pending verification (cần workstation)
- [ ] Run sync_context_files.py
- [ ] Run upload_vault_templates.sh
- [ ] Apply docker-compose.override.yml + recreate
- [ ] Telegram test: "xem các task hiện có" → deo
- [ ] Telegram test: "tạo bảng lương tháng 5/2026 với 3 nhân viên test" → finance → office → Drive link

---

## [0.2.0] - 2026-05-14

### Added
- **GoClaw running** on Xeon workstation (port 18790)
- **Telegram bot** `@condeobot` connected and routing to `deo` agent
- **Claude CLI provider** authenticated in container (Pro subscription)
  - `deo` → claude-cli / claude-sonnet
  - `it-dev-agent` → claude-cli / claude-opus
  - `office-agent` → claude-cli / claude-sonnet
- **Google Drive integration** via rclone
  - Token refreshed and working
  - `gdrive-upload.sh` script deployed to workspace
  - Upload → get shareable link → send to Telegram
- **Context files deployed** to GoClaw DB (`agent_context_files`):
  - `deo`: SOUL, IDENTITY, AGENTS, CAPABILITIES, USER_PREDEFINED
  - `office-admin-agent`: SOUL, IDENTITY, AGENTS, CAPABILITIES
  - `office-agent`: SOUL (others already custom), TOOLS (new)
- **Tailscale access**: GoClaw accessible at `http://100.90.129.11:18790` from any Tailscale device
- **Tenant setup**: Vincent (7293498822) and tung added to Master tenant as admin
- **Hooks fixed**: `eos-*` hooks disabled (were blocking all messages due to missing Enterprise OS API)
- **Persistence scripts**: `setup_all_tools.sh` and `setup_credentials.sh` for post-recreate recovery

### Changed
- Context files updated from English default templates to Vietnamese role-specific content
- Agent `deo` provider changed from OpenAI to claude-cli
- `.env` updated: Anthropic API key, Telegram bot token, Telegram owner ID

### Architecture
- Confirmed: context files live in `agent_context_files` DB table, not filesystem
- Confirmed: workspace volume path is `goclaw_goclaw-workspace` → `/app/workspace/`
- Confirmed: `goclaw` user HOME is `/app` (credentials at `/app/.claude/`)

### Docs
- `docs/MASTER_PLAN_v3.md` — full architecture, DB schema, agent hierarchy
- `docs/STORAGE_DESIGN.md` — input/vault/output/Drive pipeline
- `docs/TEMPLATE_NOTES.md` — GoClaw context file template guide

---

## [0.1.0] - 2026-05-14

### Added
- Initial project structure
- Master Plan v3 document
- Agent SOUL.md templates (deo, office-admin-agent, office-agent)
- GoClaw custom tool: `gdrive_upload.json`
- Docker compose override for input bind-mount
- DB schema: `deo.*` (15 tables)
- GitHub repo: https://github.com/vucaotung/deo-os
