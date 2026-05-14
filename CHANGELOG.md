# Changelog

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
