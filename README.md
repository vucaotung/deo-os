# Dẹo OS — Enterprise AI Agent Platform

> AI Hub + AI Agent cho doanh nghiệp đa công ty
> Powered by GoClaw · Claude Code · PostgreSQL · Google Drive

## Quick Start

```bash
git clone https://github.com/vucaotung/deo-os.git
cd deo-os
cp infrastructure/docker/.env.example .env
# Fill in API keys, then:
docker compose -f infrastructure/docker/docker-compose.yml up -d
```

## Architecture

```
Telegram/Zalo/Webapp
        ↓
  GoClaw Gateway (AI Hub)
  ├── L0: deo (COO Agent)
  ├── L1: office-admin-agent (Team Lead)
  ├── L2: finance, legal, hr, crm, pm, marketing, it-dev
  └── L3: office-agent (File Formatter)
        ↓
  PostgreSQL (Business Data)
        ↓
  Google Drive (Final Outputs)
        ↓
  Telegram link → User
```

## Storage Layers

| Layer | Location | Purpose |
|-------|----------|---------|
| Input | `C:\deo-inputs\` (Windows bind mount) | Human drops files |
| Vault | GoClaw workspace volume `/app/workspace/02_VAULT/` | Templates, rules, knowledge |
| WIP | `/app/workspace/03_SPRINTS/` | Agent drafts |
| Output | `/app/workspace/04_OUTPUTS/` → Google Drive | Final files |
| Archive | `/app/workspace/Z_ARCHIVE/` | Done tasks |

## Docs

- [Master Plan v3](docs/MASTER_PLAN_v3.md)
- [Agent Setup](docs/AGENT_SETUP.md)
- [Storage Design](docs/STORAGE_DESIGN.md)
- [DB Schema](docs/DB_SCHEMA.md)
- [Deploy Guide](docs/DEPLOY_GUIDE.md)
