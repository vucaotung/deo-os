# GoClaw Context File Templates — Notes

## File Storage

Context files are stored in the **PostgreSQL database** (`agent_context_files` table), NOT read from the filesystem directly.

To update context files:
1. Via GoClaw dashboard: Agents → [agent] → Context Files
2. Via Python script (see `scripts/update_context.py`)
3. Agents can self-update via `write_file()` tool call

## File Types Per Agent (predefined)

| File | Scope | Purpose |
|------|-------|---------|
| SOUL.md | agent-level | Personality, values, vibe — WHO you ARE |
| IDENTITY.md | agent-level | Name, emoji, creature, purpose |
| AGENTS.md | agent-level | Operating rules — HOW you work |
| CAPABILITIES.md | agent-level | Domain expertise — WHAT you can do |
| TOOLS.md | agent-level | Environment-specific notes (paths, scripts) |
| USER_PREDEFINED.md | agent-level | Baseline rules for ALL users |
| BOOTSTRAP.md | per-user | First-run ritual (auto-clears after) |
| USER.md | per-user | Personal context about individual user |
| TEAM.md | auto-generated | Never write manually — GoClaw generates it |

## Key Rules

1. **SOUL.md** = personality only, 100-200 lines max
2. **AGENTS.md** = behavioral rules (memory, style, platform formatting)
3. **CAPABILITIES.md** = expertise resume
4. **TOOLS.md** = local paths, script locations, device names
5. **USER_PREDEFINED.md** = owner definition here — cannot be overridden via chat
6. **TEAM.md** = auto-generated at runtime, never edit manually

## Workspace Structure

```
/app/workspace/{agent_key}/
├── {agent_key}/          ← agent-level context files (SOUL.md, etc.)
│   └── SOUL.md, IDENTITY.md, AGENTS.md, CAPABILITIES.md, TOOLS.md
└── {user_id}/            ← per-user files (USER.md, MEMORY.md, etc.)
    └── USER.md, MEMORY.md, BOOTSTRAP.md
```

## After Container Recreate

Context files in DB persist. But installed tools (claude CLI, rclone) and credentials need reinstall:

```bash
docker exec -u root goclaw-goclaw-1 sh /app/workspace/setup_all_tools.sh
docker exec -u root goclaw-goclaw-1 sh /app/workspace/setup_credentials.sh
```

Scripts are in the persistent workspace volume — they survive container recreate.
