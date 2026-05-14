---
title: Storage Design — Dẹo OS
updated: 2026-05-14
---

# Storage Design

## Overview

```
┌─────────────────────────────────────────────────────────┐
│  INPUT (Temporary — Windows Local)                      │
│  C:\deo-inputs\{dept}\                                  │
│  → Human drops files here                               │
│  → Bind-mounted into Docker: /app/workspace/05_INPUTS/  │
│  → Auto-cleaned after agent processes                   │
└──────────────────────┬──────────────────────────────────┘
                       │ agent reads (markitdown MCP)
                       ▼
┌─────────────────────────────────────────────────────────┐
│  VAULT (Persistent — Docker Volume)                     │
│  goclaw_goclaw-workspace → /app/workspace/              │
│  ├── 01_AGENTS/     ← context files (SOUL.md etc)       │
│  ├── 02_VAULT/      ← templates, rules, knowledge       │
│  ├── 03_SPRINTS/    ← WIP drafts (auto-rotated)         │
│  ├── 04_OUTPUTS/    ← generated files (staging)         │
│  └── Z_ARCHIVE/     ← done, never deleted               │
└──────────────────────┬──────────────────────────────────┘
                       │ rclone copy (after office-agent done)
                       ▼
┌─────────────────────────────────────────────────────────┐
│  GOOGLE DRIVE (Final — Cloud)                           │
│  Remote: gdrive (rclone, already configured)            │
│  /Dẹo Enterprise OS/                                    │
│  ├── Kế Toán/Bảng Lương/                                │
│  ├── Kế Toán/Báo Cáo/                                   │
│  ├── Pháp Chế/Hợp Đồng/                                 │
│  ├── HR/Quyết Định/                                     │
│  ├── Dự Án/{PRJ-CODE}/                                  │
│  └── Marketing/                                         │
│                                                         │
│  After upload: rclone link → shareable URL              │
│  → Send to Telegram/Zalo via GoClaw channel             │
└─────────────────────────────────────────────────────────┘
```

## 1. Input Storage

### Local Windows Folder
```
C:\deo-inputs\
├── ke-toan\          ← Drop: invoices, receipts, salary data
├── legal\            ← Drop: contract drafts, partner docs
├── hr\               ← Drop: CVs, employee forms
├── crm\              ← Drop: client data, lead lists
├── marketing\        ← Drop: campaign briefs, assets
├── du-an\            ← Drop: project docs, specs
└── it\               ← Drop: requirements, bug reports
```

### Docker Bind Mount (docker-compose.override.yml)
```yaml
services:
  goclaw:
    volumes:
      - C:/deo-inputs:/app/workspace/05_INPUTS
```

### File Lifecycle
```
Human drops file → C:\deo-inputs\ke-toan\salary-data.xlsx
                              ↓
Agent reads: /app/workspace/05_INPUTS/ke-toan/salary-data.xlsx
                              ↓
After processing: file moved to Z_ARCHIVE/YYYY-MM/
                              ↓
C:\deo-inputs\ke-toan\ auto-cleared
```

## 2. Vault Storage

### Location
Docker named volume `goclaw_goclaw-workspace` → `/app/workspace/`

### Structure (3-level max depth)
```
/app/workspace/
│
├── 01_AGENTS/                    ← LEVEL 1: Agent namespace
│   └── {agent_key}/              ← LEVEL 2: Per agent
│       ├── SOUL.md               ← LEVEL 3: Context files
│       ├── IDENTITY.md
│       ├── CAPABILITIES.md
│       └── TOOLS.md
│
├── 02_VAULT/                     ← LEVEL 1: Knowledge base
│   ├── 01_company/               ← LEVEL 2: Company info
│   │   ├── company-info.md       ← LEVEL 3: SSOT docs
│   │   └── org-chart.md
│   ├── 02_templates/             ← LEVEL 2: File templates
│   │   ├── ke-toan/
│   │   │   ├── bang-luong.md     ← LEVEL 3: Template files
│   │   │   └── phieu-thu-chi.md
│   │   ├── legal/
│   │   └── brand/
│   ├── 03_rules/                 ← LEVEL 2: Business rules
│   │   ├── bhxh-2025.md
│   │   └── thue-tncn.md
│   └── 04_projects/              ← LEVEL 2: Project context
│       └── PRJ-001_mo-rong.md
│
├── 03_SPRINTS/                   ← WIP (auto-rotate monthly)
│   └── 2026-05/
│
├── 04_OUTPUTS/                   ← Staging before Drive upload
│   └── {dept}/YYYY-MM/
│
├── 05_INPUTS/                    ← Bind-mounted from Windows
│   └── {dept}/
│
└── Z_ARCHIVE/                    ← Never deleted
    └── YYYY-MM/
```

## 3. Google Drive Output

### Remote Config
```
Remote name: gdrive
Type: Google Drive
Config: /app/workspace/rclone.conf (already configured ✅)
Root folder: /Dẹo Enterprise OS/
```

### Drive Structure
```
My Drive/Dẹo Enterprise OS/
├── Kế_Toán/
│   ├── Bang_Luong/YYYY-MM/
│   ├── Bao_Cao/YYYY-MM/
│   └── Chung_Tu/YYYY-MM/
├── Phap_Che/
│   └── Hop_Dong/YYYY/
├── HR/
│   └── Quyet_Dinh/YYYY/
├── Du_An/
│   └── {PRJ-CODE}/
└── Marketing/
    └── YYYY-MM/
```

### Upload + Link Flow
```bash
# Step 1: Install rclone in container (one-time)
docker exec -u root goclaw-goclaw-1 apk add rclone

# Step 2: GoClaw custom tool triggers upload
rclone copy /app/workspace/04_OUTPUTS/ke-toan/2026-05/bang-luong.xlsx \
  gdrive:/Dẹo Enterprise OS/Kế_Toán/Bang_Luong/2026-05/ \
  --config /app/workspace/rclone.conf

# Step 3: Get shareable link
rclone link gdrive:/Dẹo Enterprise OS/Kế_Toán/Bang_Luong/2026-05/bang-luong.xlsx \
  --config /app/workspace/rclone.conf
# → https://drive.google.com/file/d/XXXX/view

# Step 4: GoClaw sends link to Telegram automatically
```

## 4. GoClaw Custom Tools for Drive

### Tool: gdrive_upload
```json
{
  "name": "gdrive_upload",
  "description": "Upload a file from workspace to Google Drive and return shareable link",
  "parameters": {
    "type": "object",
    "properties": {
      "local_path": {
        "type": "string",
        "description": "Relative path from /app/workspace/ e.g. 04_OUTPUTS/ke-toan/2026-05/file.xlsx"
      },
      "drive_folder": {
        "type": "string",
        "description": "Google Drive folder path e.g. Kế_Toán/Bang_Luong/2026-05"
      }
    },
    "required": ["local_path", "drive_folder"]
  },
  "command": "rclone copy /app/workspace/{{.local_path}} \"gdrive:/Dẹo Enterprise OS/{{.drive_folder}}/\" --config /app/workspace/rclone.conf && rclone link \"gdrive:/Dẹo Enterprise OS/{{.drive_folder}}/$(basename {{.local_path}})\" --config /app/workspace/rclone.conf",
  "timeout_seconds": 60,
  "enabled": true
}
```

### Tool: gdrive_list
```json
{
  "name": "gdrive_list",
  "description": "List files in a Google Drive folder",
  "parameters": {
    "properties": {
      "drive_folder": { "type": "string" }
    }
  },
  "command": "rclone ls \"gdrive:/Dẹo Enterprise OS/{{.drive_folder}}\" --config /app/workspace/rclone.conf",
  "timeout_seconds": 30
}
```

## 5. Complete Output Pipeline

```
office-agent creates file:
  → /app/workspace/04_OUTPUTS/ke-toan/2026-05/bang-luong.xlsx

office-agent calls gdrive_upload:
  → Upload to Drive: Kế_Toán/Bang_Luong/2026-05/
  → Returns: https://drive.google.com/file/d/XXXX/view

office-agent reports to office-admin-agent:
  "✅ Bảng lương T5/2026 hoàn thành.
   📎 Link: https://drive.google.com/file/d/XXXX/view"

office-admin-agent → deo → Telegram to Vincent:
  "✅ Bảng lương tháng 5 đã xong!
   📁 Google Drive: [Bang_Luong_T5_2026]
   🔗 https://drive.google.com/file/d/XXXX/view"
```

## 6. Setup Commands

### Install rclone + mount input folder
```bash
# 1. Install rclone in container
docker exec -u root goclaw-goclaw-1 apk add --no-cache rclone

# 2. Test Drive connection
docker exec goclaw-goclaw-1 rclone lsd gdrive: \
  --config /app/workspace/rclone.conf

# 3. Create Drive root folder
docker exec goclaw-goclaw-1 rclone mkdir \
  "gdrive:/Dẹo Enterprise OS" \
  --config /app/workspace/rclone.conf

# 4. Add bind mount for inputs (edit docker-compose.override.yml)
# Then: docker compose up -d (no rebuild needed)
```
