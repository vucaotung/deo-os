#!/usr/bin/env python3
"""
Sync context files from goclaw/agents/ and goclaw/users/ into GoClaw PostgreSQL.

Usage (chạy trên Win10 workstation hoặc máy có route đến Postgres):
    DSN=postgresql://goclaw:goclaw@localhost:5432/goclaw \\
        python3 goclaw/scripts/sync_context_files.py

Flags:
    --dry-run     Show planned updates without writing
    --agent KEY   Only sync one agent (e.g. finance-agent)
    --vincent-id N  Numeric user.id of Vincent (default: lookup by telegram_id=7293498822)
"""
from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path

try:
    import psycopg2
except ImportError:
    sys.exit("pip install psycopg2-binary")

REPO_ROOT = Path(__file__).resolve().parents[2]
AGENTS_DIR = REPO_ROOT / "goclaw" / "agents"
USERS_DIR = REPO_ROOT / "goclaw" / "users"

# Files that exist as agent-level context (scope=agent)
AGENT_FILES = ["SOUL.md", "IDENTITY.md", "AGENTS.md", "CAPABILITIES.md", "TOOLS.md"]


def upsert_agent_context(cur, agent_key: str, file_name: str, content: str, dry: bool):
    cur.execute("SELECT id FROM agents WHERE agent_key = %s", (agent_key,))
    row = cur.fetchone()
    if not row:
        print(f"  [skip] agent not found: {agent_key}")
        return
    agent_id = row[0]
    if dry:
        print(f"  [dry] would upsert {agent_key}/{file_name} ({len(content)} bytes)")
        return
    # Try UPDATE first; INSERT if no rows affected.
    cur.execute(
        """
        UPDATE agent_context_files
        SET content = %s, updated_at = NOW()
        WHERE agent_id = %s AND file_name = %s AND (user_id IS NULL)
        """,
        (content, agent_id, file_name),
    )
    if cur.rowcount == 0:
        cur.execute(
            """
            INSERT INTO agent_context_files (agent_id, file_name, content, scope, created_at, updated_at)
            VALUES (%s, %s, %s, 'agent', NOW(), NOW())
            """,
            (agent_id, file_name, content),
        )
        print(f"  [ins] {agent_key}/{file_name}")
    else:
        print(f"  [upd] {agent_key}/{file_name}")


def upsert_user_context(cur, agent_key: str, user_id: int, file_name: str, content: str, dry: bool):
    cur.execute("SELECT id FROM agents WHERE agent_key = %s", (agent_key,))
    row = cur.fetchone()
    if not row:
        print(f"  [skip] agent not found: {agent_key}")
        return
    agent_id = row[0]
    if dry:
        print(f"  [dry] would upsert USER.md for {agent_key} / user_id={user_id} ({len(content)} bytes)")
        return
    cur.execute(
        """
        UPDATE agent_context_files
        SET content = %s, updated_at = NOW()
        WHERE agent_id = %s AND file_name = %s AND user_id = %s
        """,
        (content, agent_id, file_name, user_id),
    )
    if cur.rowcount == 0:
        cur.execute(
            """
            INSERT INTO agent_context_files (agent_id, user_id, file_name, content, scope, created_at, updated_at)
            VALUES (%s, %s, %s, %s, 'user', NOW(), NOW())
            """,
            (agent_id, user_id, file_name, content),
        )
        print(f"  [ins] {agent_key}/USER.md (user_id={user_id})")
    else:
        print(f"  [upd] {agent_key}/USER.md (user_id={user_id})")


def lookup_vincent_id(cur) -> int | None:
    cur.execute("SELECT id FROM users WHERE telegram_id = '7293498822' LIMIT 1")
    row = cur.fetchone()
    return row[0] if row else None


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--dry-run", action="store_true")
    p.add_argument("--agent", help="Only sync this agent_key")
    p.add_argument("--vincent-id", type=int, help="Override Vincent user_id")
    args = p.parse_args()

    dsn = os.environ.get("DSN", "postgresql://goclaw:goclaw@localhost:5432/goclaw")
    print(f"Connecting to {dsn} ...")
    conn = psycopg2.connect(dsn)
    cur = conn.cursor()

    # 1. Agent-level files
    for agent_dir in sorted(AGENTS_DIR.iterdir()):
        if not agent_dir.is_dir():
            continue
        agent_key = agent_dir.name
        if args.agent and agent_key != args.agent:
            continue
        print(f"\n== {agent_key} ==")
        for fname in AGENT_FILES:
            fpath = agent_dir / fname
            if not fpath.exists():
                continue
            content = fpath.read_text(encoding="utf-8")
            upsert_agent_context(cur, agent_key, fname, content, args.dry_run)

    # 2. Vincent per-user USER.md → applied to deo + office-admin-agent
    vincent_id = args.vincent_id or lookup_vincent_id(cur)
    user_md = USERS_DIR / "vincent_USER.md"
    if vincent_id and user_md.exists():
        content = user_md.read_text(encoding="utf-8")
        print(f"\n== USER.md for Vincent (user_id={vincent_id}) ==")
        for ak in ("deo", "office-admin-agent"):
            if args.agent and ak != args.agent:
                continue
            upsert_user_context(cur, ak, vincent_id, "USER.md", content, args.dry_run)
    else:
        print("\n[warn] Skipping USER.md sync — Vincent user_id not found (pass --vincent-id N)")

    if args.dry_run:
        conn.rollback()
        print("\n[dry-run] No changes committed.")
    else:
        conn.commit()
        print("\n[done] Committed.")
    cur.close()
    conn.close()


if __name__ == "__main__":
    main()
