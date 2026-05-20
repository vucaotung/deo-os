#!/usr/bin/env python3
"""
Sync context files from goclaw/agents/ and goclaw/users/ into GoClaw PostgreSQL.

Usage (chạy từ Win10 workstation):
    python goclaw\\scripts\\sync_context_files.py [options]

Options:
    --dry-run     Show planned updates without writing
    --agent KEY   Only sync one agent (e.g. finance-agent)
    --vault       Also sync vault templates from goclaw/vault/

Env:
    DSN   PostgreSQL DSN (default: postgresql://goclaw:goclaw@localhost:5432/goclaw)
"""
from __future__ import annotations

import argparse
import hashlib
import os
import sys
from pathlib import Path

try:
    import psycopg2
    import psycopg2.extras
except ImportError:
    sys.exit("pip install psycopg2-binary")

REPO_ROOT = Path(__file__).resolve().parents[2]
AGENTS_DIR = REPO_ROOT / "goclaw" / "agents"
USERS_DIR  = REPO_ROOT / "goclaw" / "users"
VAULT_DIR  = REPO_ROOT / "goclaw" / "vault"

AGENT_FILES = ["SOUL.md", "IDENTITY.md", "AGENTS.md", "CAPABILITIES.md", "TOOLS.md"]

# Agents that get per-user USER.md for Vincent
USER_MD_AGENTS = ["deo", "office-admin-agent"]

TENANT_ID = "0193a5b0-7000-7000-8000-000000000001"
VINCENT_USER_ID = "7293498822"


# ── helpers ──────────────────────────────────────────────────────────────────

def get_agent_ids(cur) -> dict[str, str]:
    cur.execute("SELECT agent_key, id FROM agents")
    return {row[0]: row[1] for row in cur.fetchall()}


def upsert_agent_context(cur, agent_id: str, file_name: str, content: str, dry: bool, agent_key: str):
    if dry:
        print(f"  [dry] {agent_key}/{file_name} ({len(content)} bytes)")
        return
    cur.execute(
        """
        INSERT INTO agent_context_files (agent_id, file_name, content, tenant_id)
        VALUES (%s, %s, %s, %s)
        ON CONFLICT (agent_id, file_name)
        DO UPDATE SET content = EXCLUDED.content, updated_at = NOW()
        """,
        (agent_id, file_name, content, TENANT_ID),
    )
    action = "ins" if cur.statusmessage.startswith("INSERT") else "upd"
    print(f"  [{action}] {agent_key}/{file_name}")


def upsert_user_context(cur, agent_id: str, file_name: str, content: str, dry: bool, agent_key: str):
    if dry:
        print(f"  [dry] USER.md for {agent_key} / user={VINCENT_USER_ID} ({len(content)} bytes)")
        return
    cur.execute(
        """
        INSERT INTO user_context_files (agent_id, user_id, file_name, content, tenant_id)
        VALUES (%s, %s, %s, %s, %s)
        ON CONFLICT (agent_id, user_id, file_name)
        DO UPDATE SET content = EXCLUDED.content, updated_at = NOW()
        """,
        (agent_id, VINCENT_USER_ID, file_name, content, TENANT_ID),
    )
    action = "ins" if cur.statusmessage.startswith("INSERT") else "upd"
    print(f"  [{action}] {agent_key}/USER.md (user={VINCENT_USER_ID})")


def upsert_vault_doc(cur, path: str, title: str, content: str, dry: bool):
    """Insert/update vault_documents (scope=shared) + vault_versions."""
    content_hash = hashlib.sha256(content.encode()).hexdigest()
    # summary = first non-empty line
    summary = next((l.strip().lstrip("#").strip() for l in content.splitlines() if l.strip()), title)[:500]

    if dry:
        print(f"  [dry] vault shared/{path} ({len(content)} bytes)")
        return

    # Upsert vault_documents
    # Unique: (tenant_id, COALESCE(agent_id, uuid-zero), COALESCE(team_id, uuid-zero), scope, path)
    # For shared scope: agent_id IS NULL, team_id IS NULL
    cur.execute(
        """
        INSERT INTO vault_documents (tenant_id, scope, path, title, doc_type, content_hash, summary)
        VALUES (%s, 'shared', %s, %s, 'note', %s, %s)
        ON CONFLICT (tenant_id,
                     COALESCE(agent_id, '00000000-0000-0000-0000-000000000000'::uuid),
                     COALESCE(team_id,  '00000000-0000-0000-0000-000000000000'::uuid),
                     scope, path)
        DO UPDATE SET title = EXCLUDED.title,
                      content_hash = EXCLUDED.content_hash,
                      summary = EXCLUDED.summary,
                      updated_at = NOW()
        RETURNING id
        """,
        (TENANT_ID, path, title, content_hash, summary),
    )
    doc_id = cur.fetchone()[0]

    # Upsert vault_versions: always insert new version or update existing content_hash
    cur.execute(
        "SELECT id, version FROM vault_versions WHERE doc_id = %s ORDER BY version DESC LIMIT 1",
        (doc_id,),
    )
    existing = cur.fetchone()
    if existing:
        cur.execute(
            "UPDATE vault_versions SET content = %s WHERE id = %s",
            (content, existing[0]),
        )
        print(f"  [upd] vault/{path} (v{existing[1]})")
    else:
        cur.execute(
            "INSERT INTO vault_versions (doc_id, version, content, changed_by) VALUES (%s, 1, %s, 'sync_script')",
            (doc_id, content),
        )
        print(f"  [ins] vault/{path} (v1)")


# ── main ─────────────────────────────────────────────────────────────────────

def main():
    p = argparse.ArgumentParser()
    p.add_argument("--dry-run", action="store_true")
    p.add_argument("--agent", help="Only sync this agent_key")
    p.add_argument("--vault", action="store_true", help="Also sync vault templates")
    args = p.parse_args()

    dsn = os.environ.get("DSN", "postgresql://goclaw:goclaw@localhost:5432/goclaw")
    print(f"Connecting: {dsn}")
    conn = psycopg2.connect(dsn)
    cur = conn.cursor()

    agent_ids = get_agent_ids(cur)
    print(f"Found {len(agent_ids)} agents in DB\n")

    # 1. Agent-level context files
    print("=== Agent context files ===")
    for agent_dir in sorted(AGENTS_DIR.iterdir()):
        if not agent_dir.is_dir():
            continue
        agent_key = agent_dir.name
        if args.agent and agent_key != args.agent:
            continue
        if agent_key not in agent_ids:
            print(f"\n[skip] {agent_key} — not in agents table")
            continue
        print(f"\n{agent_key}:")
        for fname in AGENT_FILES:
            fpath = agent_dir / fname
            if not fpath.exists():
                continue
            content = fpath.read_text(encoding="utf-8")
            upsert_agent_context(cur, agent_ids[agent_key], fname, content, args.dry_run, agent_key)

    # 2. Vincent USER.md → user_context_files
    user_md_path = USERS_DIR / "vincent_USER.md"
    if user_md_path.exists():
        content = user_md_path.read_text(encoding="utf-8")
        print(f"\n=== Vincent USER.md (user_id={VINCENT_USER_ID}) ===")
        for ak in USER_MD_AGENTS:
            if args.agent and ak != args.agent:
                continue
            if ak not in agent_ids:
                print(f"  [skip] {ak} — not in agents table")
                continue
            upsert_user_context(cur, agent_ids[ak], "USER.md", content, args.dry_run, ak)

    # 3. Vault templates (opt-in via --vault flag)
    if args.vault and VAULT_DIR.exists():
        print("\n=== Vault templates ===")
        VAULT_TITLES = {
            "02_templates/ke-toan/bang-luong.md":        "Template Bảng Lương",
            "02_templates/legal/hop-dong-lao-dong.md":   "Template Hợp Đồng Lao Động",
            "02_templates/hr/don-xin-nghi-phep.md":      "Template Đơn Xin Nghỉ Phép",
            "01_company/company-info.md":                 "Company Info",
        }
        for rel_path, title in VAULT_TITLES.items():
            fpath = VAULT_DIR / rel_path
            if not fpath.exists():
                print(f"  [skip] {rel_path} — file not found")
                continue
            content = fpath.read_text(encoding="utf-8")
            upsert_vault_doc(cur, rel_path, title, content, args.dry_run)

    if args.dry_run:
        conn.rollback()
        print("\n[dry-run] No changes committed.")
    else:
        conn.commit()
        print("\n[done] All changes committed.")

    cur.close()
    conn.close()


if __name__ == "__main__":
    main()
