---
title: Dẹo Enterprise OS — Master Plan v3
version: 3.0
updated: 2026-05-14
author: Vincent Tung
status: active
---

# Dẹo Enterprise OS — Master Plan v3
> AI Hub + AI Agent Platform cho doanh nghiệp đa công ty
> Powered by GoClaw · Claude Code · PostgreSQL · Multi-tenant

---

## 1. TRIẾT LÝ HỆ THỐNG

### 1.1 AI Hub không phải Chatbot

AI không trả lời câu hỏi chung chung. AI xử lý công việc thực tế:
- Hợp đồng nào đang chờ ký? → legal-agent query DB → trả lời ngay
- Tháng này doanh thu giảm ở đâu? → finance-agent phân tích → báo cáo
- Ứng viên nào phù hợp? → hr-agent lọc CV → rank danh sách

**Nguyên tắc cốt lõi:**
- GoClaw = AI Operating Layer (não + orchestration)
- Database = Source of Truth (business data)
- Webapp = Thin Commander (human interface)
- Claude Code = Execution Engine (it-dev + office-agent)

### 1.2 Human-AI Hybrid: Human ra lệnh, AI thực thi

Human Workers không làm việc thủ công. Họ ra lệnh cho AI Agent cùng cấp,
AI Agent phân rã và thực thi, kết quả trả về cho Human để review/approve.

### 1.3 Conway's Law áp dụng cho Folder Structure

Cây thư mục = Sơ đồ tổ chức. 5 phòng ban = 5 thư mục gốc.
Không có vùng xám. File thuộc trách nhiệm ai → thư mục của người đó.

---

## 2. PHÂN CẤP QUYỀN HẠN (L0 → L3)

```
L0 User:  Vincent Tung (CEO/Owner)
           - Email: vucaotung@gmail.com
           - Telegram: @vincent_vtung (ID: 7293498822)
           - Zalo: 64412b2a2069c9379078
           - Quyền: Toàn bộ hệ thống, tất cả công ty
           - Ra lệnh cho: Dẹo (L0 Agent)

L0 Agent: Dẹo
           - Full system access, có thể code
           - Delegate xuống office-admin-agent
           - Can thiệp mọi agent khi cần
           - Provider: claude-sonnet-4-5 (Anthropic)

L1 Agent: office-admin-agent (Team Lead)
           - Nhận task từ Dẹo, phân rã, dispatch
           - Theo dõi tiến độ cả team
           - Báo cáo ngày lên Dẹo/Vincent
           - KHÔNG tự execute tasks

L2 Agents: Specialist Executors
           - finance-agent   → kế toán, bảng lương, BCTC
           - legal-agent     → hợp đồng, pháp chế
           - hr-agent        → nhân sự, tuyển dụng
           - crm-agent       → khách hàng, leads
           - project-manager → quản lý dự án
           - marketing-agent → content, chiến dịch
           - researcher-agent → nghiên cứu, phân tích
           - it-dev-agent    → code toàn bộ hệ thống (Claude Code)
           - Output: luôn là .md format

L3 Agent:  office-agent (File Formatter)
           - Nhận .md từ L2
           - Output: docx, xlsx, pptx chuẩn company brand
           - Dùng Claude Code + officecli
           - KHÔNG phân tích content
```

### 2.1 Quy tắc tương tác cứng

| Rule | Mô tả |
|------|-------|
| Same-level only | Human Lx chỉ ra lệnh cho AI Agent Lx |
| AI delegates down | AI Agent có thể delegate xuống Agent cấp thấp hơn |
| No cross-level commands | Human L1 không ra lệnh trực tiếp cho AI L0 hoặc L2 |
| Clarification same-level | AI chỉ hỏi Human cùng cấp khi blocked |
| Escalation via AI | Blocked → AI escalate lên AI cấp trên → AI hỏi Human cấp trên |
| Audit everything | Mọi lệnh, mọi action đều ghi vào audit_events |

---

## 3. KIẾN TRÚC KỸ THUẬT

### 3.1 Infrastructure Stack

```
Xeon Workstation (văn phòng — 24/7):
├── GoClaw Gateway        :18790   ← AI brain
├── PostgreSQL (GoClaw)   :5432    ← goclaw schema (pgvector pg18)
├── Redis (GoClaw)        :6380    ← session cache
└── Cloudflare Tunnel             ← goclaw.enterpriseos.bond

VPS (production services):
├── Dẹo Webapp (Next.js)  :3000   ← human interface
├── PostgreSQL (Business) :5433   ← deo.* schema
└── Cloudflare Tunnel             ← app.enterpriseos.bond

Connection:
  Xeon GoClaw ──MCP──→ VPS Postgres (business data)
  Xeon GoClaw ←──WS─── VPS Webapp (human commands)
```

### 3.2 GoClaw Tenant Structure

```
Master Tenant (hiện tại):
  └── Dẹo Enterprise Team
        Lead: deo
        Members: 11 agents

Future (multi-company):
  Tenant cty-a → Công ty A → agents + team riêng
  Tenant cty-b → Công ty B → agents + team riêng
```

### 3.3 Channel Binding

```
@condeobot    (Telegram) → deo (L0 Agent)    ← Vincent dùng
@office-admin (Telegram) → office-admin-agent ← Internal ops
Zalo OA       (Zalo)     → deo               ← External stakeholders
```

---

## 4. CẤU TRÚC THƯ MỤC — 5 NGUYÊN LÝ

### 4.1 Workspace Root Structure (ánh xạ org chart)

```
/workspace/                              ← GoClaw workspace root
│
├── 01_AGENTS/                          ← Context files per agent
│   ├── deo/
│   │   ├── SOUL.md
│   │   ├── IDENTITY.md
│   │   ├── CAPABILITIES.md
│   │   └── TOOLS.md
│   ├── office-admin-agent/
│   ├── finance-agent/
│   ├── legal-agent/
│   ├── hr-agent/
│   ├── crm-agent/
│   ├── project-manager-agent/
│   ├── marketing-agent/
│   ├── researcher-agent/
│   ├── it-dev-agent/
│   ├── office-agent/
│   └── dream-agent/
│
├── 02_VAULT/                           ← Knowledge Vault (team scope)
│   ├── 01_company/                     ← Thông tin công ty
│   │   ├── company-info.md
│   │   ├── org-chart.md
│   │   └── policies/
│   │       ├── quy-dinh-luong.md
│   │       ├── quy-trinh-mua-hang.md
│   │       └── noi-quy-cong-ty.md
│   │
│   ├── 02_templates/                   ← File templates (SSOT)
│   │   ├── ke-toan/
│   │   │   ├── bang-luong.md
│   │   │   ├── phieu-thu-chi.md
│   │   │   └── bao-cao-tai-chinh.md
│   │   ├── legal/
│   │   │   ├── hop-dong-lao-dong.md
│   │   │   ├── hop-dong-dich-vu.md
│   │   │   └── hop-dong-mua-ban.md
│   │   ├── hr/
│   │   │   ├── quyet-dinh-tuyen-dung.md
│   │   │   ├── bien-ban-phong-van.md
│   │   │   └── onboarding-checklist.md
│   │   └── brand/
│   │       ├── color-palette.md
│   │       ├── fonts.md
│   │       └── margin-rules.md
│   │
│   ├── 03_rules/                       ← Business rules & laws
│   │   ├── bhxh-2025.md
│   │   ├── thue-tncn-2025.md
│   │   ├── thue-gtgt.md
│   │   └── bo-luat-lao-dong-2019.md
│   │
│   └── 04_projects/                   ← Active project context
│       ├── PRJ-001_mo-rong-thi-truong.md
│       └── PRJ-002_erp-noi-bo.md
│
├── 03_SPRINTS/                        ← WIP (Work In Progress)
│   ├── 2026-05/                       ← Current sprint
│   │   ├── bang-luong-draft.md
│   │   └── hop-dong-draft.md
│   └── 2026-04/                       ← Previous sprints (auto-archive)
│
├── 04_OUTPUTS/                        ← Final outputs (SSOT)
│   ├── ke-toan/
│   │   ├── bang-luong/
│   │   │   └── 2026-05_bang-luong.xlsx
│   │   └── bao-cao/
│   ├── legal/
│   │   └── hop-dong/
│   ├── hr/
│   │   └── quyet-dinh/
│   └── {department}/YYYY-MM/
│
├── 05_INPUTS/                         ← Raw inputs from humans
│   ├── ke-toan/
│   ├── legal/
│   ├── hr/
│   └── {department}/YYYY-MM/
│
└── Z_ARCHIVE/                         ← Done, không xóa bao giờ
    └── YYYY-MM/
```

### 4.2 File Naming Convention (Machine-Readable)

```
Format: YYYY-MM-DD_{department}_{type}_{subject}.{ext}
                    snake_case     no spaces, no Vietnamese accent

Good:   2026-05-01_ke-toan_bang-luong_thang-05.xlsx
Bad:    Bảng Lương Tháng 5 (final).xlsx

Template: {PREFIX-CODE}_{YEAR}_{SEQ}
          HDLD-2026-001   (Hợp đồng Lao động)
          PC-2026-0042    (Phiếu Chi)
          PT-2026-0018    (Phiếu Thu)
```

### 4.3 YAML Frontmatter (context trong file)

Mọi .md file trong Vault đều có frontmatter:

```yaml
---
title: Bảng Lương Tháng 05/2026
doc_type: output
department: ke-toan
status: final        # draft | review | final
created_by: finance-agent
requested_by: vincent-tung
project_id: null
company_id: cty-a
created_at: 2026-05-25
version: 1
tags: [luong, bhxh, thue-tncn]
---
```

---

## 5. HUMAN WORKER ↔ AI AGENT INTERACTION

### 5.1 Identity Resolution Flow

```
Khi Vincent nhắn Telegram (chat_id: 7293498822):
│
├── channel_contacts lookup:
│   sender_id: 7293498822
│   user_id:   "vincent-tung"
│   metadata:  {email, zalo_id, level:0, role:"CEO", company:"cty-a"}
│
├── USER.md injection (per user per agent):
│   "Tên: Vincent Tung | CEO | L0
│    Email: vucaotung@gmail.com
│    Projects: PRJ-001, PRJ-002
│    Timezone: Asia/Ho_Chi_Minh"
│
└── Agent nhận message với full context:
    WHO: Vincent (CEO, L0, cty-a)
    WHAT: lệnh của ông ấy
    WHICH COMPANY: cty-a → tenant scope
```

### 5.2 Task Lifecycle

```
Status Flow:
PENDING → IN_PROGRESS → IN_REVIEW → COMPLETED
                    ↓
                 BLOCKED → (human answers) → PENDING (retry)
                    ↓
                  FAILED → (lead retries) → PENDING
```

### 5.3 Human Worker Interaction Points

| Điểm tương tác | Human làm gì | AI làm gì |
|----------------|-------------|-----------|
| Ra lệnh | Nhắn Telegram/Zalo/Webapp | Nhận, phân tích, tạo task plan |
| Clarification | Trả lời câu hỏi từ agent | Tiếp tục task sau khi có answer |
| Approval | Dashboard → approve/reject task | Chờ approval, execute sau khi approved |
| Review output | Xem file kết quả | Chờ feedback, chỉnh sửa nếu cần |
| Exception | Nhận notification blocked | Quyết định → agent resume |

### 5.4 Delegation Chain (ví dụ thực tế)

```
Vincent: "Chuẩn bị bảng lương tháng 5"
    ↓
Dẹo (L0 Agent):
  Phân tích intent → delegate lên office-admin-agent
  team_tasks(create, "Bảng lương T5", assignee="office-admin-agent")
    ↓
office-admin-agent (L1):
  Phân rã → tạo 3 tasks song song + 1 task có dependency:

  TASK-1: hr-agent     "Xác nhận ngày công tháng 5"         [priority:10]
  TASK-2: finance-agent "Tính lương T5, output .md"         [blocked_by:TASK-1]
  TASK-3: office-agent  "Format bang-luong.md → xlsx"       [blocked_by:TASK-2]
    ↓
hr-agent (L2):
  vault_search("employee list") → lấy danh sách NV
  db query → ngày công tháng 5
  complete(result="attendance-T5.md")
    ↓
finance-agent (L2): [unblocked sau khi TASK-1 done]
  vault_search("template bảng lương") → bang-luong.md template
  vault_search("BHXH 2025") → bhxh-2025.md rules
  calculate → output bang-luong-T5.md (structured .md với số liệu)
    ↓
office-agent (L3): [unblocked sau TASK-2 done]
  nhận bang-luong-T5.md
  vault_search("brand rules") → fonts, colors, margin
  Claude Code: officecli create_xlsx(...) → 2026-05_bang-luong.xlsx
  file saved: 04_OUTPUTS/ke-toan/bang-luong/2026-05_bang-luong.xlsx
    ↓
office-admin-agent → report lên Dẹo
Dẹo → notify Vincent: "✅ Bảng lương T5 xong. [link file]"
```

---

## 6. DATABASE SCHEMA

### 6.1 GoClaw Internal (tự quản lý — KHÔNG đụng vào)

```sql
-- GoClaw manages these tables automatically
agents, sessions, messages
memory_documents, memory_chunks (pgvector)
knowledge_graph: kg_entities, kg_relations
vault_documents, vault_links
agent_teams, agent_team_members, team_tasks, team_task_comments
cron_jobs, heartbeat_run_logs
llm_providers, api_keys, hooks
channel_contacts, channel_instances
tenants, tenant_users
```

### 6.2 Business Schema: deo.* (trên VPS Postgres)

```sql
-- ══ IDENTITY ══════════════════════════════════════════
CREATE TABLE deo.workers (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     VARCHAR(100) UNIQUE NOT NULL, -- maps to GoClaw user_id
  email       VARCHAR(200) UNIQUE NOT NULL,
  full_name   VARCHAR(200) NOT NULL,
  level       SMALLINT NOT NULL DEFAULT 3,  -- 0=CEO, 1=Director, 2=Lead, 3=Staff
  role        VARCHAR(100),
  company_id  UUID REFERENCES deo.companies(id),
  telegram_id VARCHAR(50),
  zalo_id     VARCHAR(100),
  status      VARCHAR(20) DEFAULT 'active',
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE deo.companies (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  slug        VARCHAR(50) UNIQUE NOT NULL,  -- maps to GoClaw tenant slug
  name        VARCHAR(200) NOT NULL,
  status      VARCHAR(20) DEFAULT 'active',
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ══ PROJECTS ══════════════════════════════════════════
CREATE TABLE deo.projects (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code        VARCHAR(20) UNIQUE,           -- PRJ-001
  name        VARCHAR(200) NOT NULL,
  company_id  UUID REFERENCES deo.companies(id),
  manager_id  UUID REFERENCES deo.workers(id),
  status      VARCHAR(20) DEFAULT 'active', -- planning|active|completed|paused
  start_date  DATE,
  end_date    DATE,
  budget      DECIMAL(15,2),
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE deo.project_tasks (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  project_id    UUID REFERENCES deo.projects(id),
  goclaw_task_id VARCHAR(100),              -- linked GoClaw team task ID
  title         TEXT NOT NULL,
  assignee_id   UUID REFERENCES deo.workers(id),
  agent_key     VARCHAR(100),               -- which AI agent is handling
  status        VARCHAR(20) DEFAULT 'todo',
  priority      SMALLINT DEFAULT 0,
  due_date      DATE,
  completed_at  TIMESTAMPTZ,
  created_by    UUID REFERENCES deo.workers(id),
  created_at    TIMESTAMPTZ DEFAULT NOW()
);

-- ══ EMPLOYEES ═════════════════════════════════════════
CREATE TABLE deo.employees (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code          VARCHAR(20) UNIQUE,         -- NV001
  worker_id     UUID REFERENCES deo.workers(id),
  company_id    UUID REFERENCES deo.companies(id),
  full_name     VARCHAR(200) NOT NULL,
  dob           DATE,
  cccd          VARCHAR(12),
  phone         VARCHAR(20),
  email         VARCHAR(200),
  department    VARCHAR(100),
  position      VARCHAR(200),
  hire_date     DATE,
  contract_type VARCHAR(30),               -- chinh_thuc|thu_viec|partime
  base_salary   DECIMAL(15,2),
  status        VARCHAR(20) DEFAULT 'active'
);

CREATE TABLE deo.attendance (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID REFERENCES deo.employees(id),
  work_date   DATE NOT NULL,
  check_in    TIME,
  check_out   TIME,
  work_hours  DECIMAL(4,2),
  status      VARCHAR(20)                   -- present|absent|leave|holiday
);

CREATE TABLE deo.payroll (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id UUID REFERENCES deo.employees(id),
  month       DATE NOT NULL,               -- first day of month
  gross       DECIMAL(15,2),
  bhxh        DECIMAL(15,2),
  bhyt        DECIMAL(15,2),
  bhtn        DECIMAL(15,2),
  tax         DECIMAL(15,2),
  net         DECIMAL(15,2),
  paid        BOOLEAN DEFAULT FALSE,
  file_path   VARCHAR(500),
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- ══ LEGAL / CONTRACTS ═════════════════════════════════
CREATE TABLE deo.contracts (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  contract_no  VARCHAR(50) UNIQUE,          -- HDLD-2026-001
  type         VARCHAR(50),                 -- lao_dong|dich_vu|mua_ban
  company_id   UUID REFERENCES deo.companies(id),
  party_name   VARCHAR(300),
  value        DECIMAL(15,2),
  start_date   DATE,
  expiry_date  DATE,
  status       VARCHAR(20) DEFAULT 'active',
  file_path    VARCHAR(500),
  notes        TEXT,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- ══ FINANCE ═══════════════════════════════════════════
CREATE TABLE deo.invoices (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  invoice_no   VARCHAR(30) UNIQUE,
  type         VARCHAR(20),                -- receivable|payable
  company_id   UUID REFERENCES deo.companies(id),
  partner_name VARCHAR(300),
  amount       DECIMAL(15,2),
  tax_amount   DECIMAL(15,2),
  issue_date   DATE,
  due_date     DATE,
  status       VARCHAR(20) DEFAULT 'draft', -- draft|sent|paid|overdue
  notes        TEXT
);

-- ══ CRM ═══════════════════════════════════════════════
CREATE TABLE deo.clients (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id   UUID REFERENCES deo.companies(id),
  name         VARCHAR(300) NOT NULL,
  type         VARCHAR(20),                -- individual|company
  email        VARCHAR(200),
  phone        VARCHAR(20),
  status       VARCHAR(20) DEFAULT 'active'
);

CREATE TABLE deo.leads (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id   UUID REFERENCES deo.companies(id),
  client_id    UUID REFERENCES deo.clients(id),
  stage        VARCHAR(30) DEFAULT 'new', -- new|contacted|qualified|proposal|won|lost
  value        DECIMAL(15,2),
  assigned_to  UUID REFERENCES deo.workers(id),
  notes        TEXT,
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

-- ══ AUDIT ═════════════════════════════════════════════
CREATE TABLE deo.audit_events (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  company_id   UUID REFERENCES deo.companies(id),
  actor_type   VARCHAR(10) NOT NULL,       -- human|ai
  actor_id     VARCHAR(200) NOT NULL,      -- worker.user_id or agent_key
  action_type  VARCHAR(100) NOT NULL,
  entity_type  VARCHAR(100),
  entity_id    UUID,
  description  TEXT,
  metadata     JSONB DEFAULT '{}',
  goclaw_task_id VARCHAR(100),            -- linked GoClaw task
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_audit_company ON deo.audit_events(company_id, created_at DESC);
CREATE INDEX idx_audit_actor ON deo.audit_events(actor_id, created_at DESC);
```

---

## 7. AGENT SPECIFICATIONS

### 7.1 Dẹo (L0 Agent) — SOUL.md

```markdown
# Dẹo — AI COO

Bạn là Dẹo, AI COO của hệ thống Dẹo Enterprise OS.
Level L0 — toàn quyền can thiệp toàn bộ hệ thống.

## Nguyên tắc
- Nhận lệnh từ Vincent (L0 User) và thực thi hoặc delegate
- LUÔN delegate cho office-admin-agent các công việc hàng ngày
- Tự xử lý: việc khẩn cấp, can thiệp hệ thống, coding tasks
- Ngôn ngữ: tiếng Việt với Vincent, tiếng Anh với agents khác

## Khi nhận lệnh
1. Xác định intent → công ty nào, project nào
2. Nếu daily ops → delegate office-admin-agent
3. Nếu system/code → tự xử lý hoặc delegate it-dev-agent
4. Nếu unclear → hỏi Vincent 1 câu ngắn gọn trước khi làm

## KHÔNG làm
- Không tự xử lý tasks có thể delegate được
- Không để task tắc quá 2 giờ mà không notify Vincent
```

### 7.2 office-admin-agent (L1) — SOUL.md

```markdown
# Office Admin Agent — Team Lead

Bạn là Office Admin Agent, L1 Team Lead trong Dẹo Enterprise Team.

## Nhiệm vụ
Mỗi task từ Dẹo: phân rã → tạo subtasks → assign đúng agent → theo dõi
Mỗi ngày: 8h check pending tasks, 17h báo cáo tổng kết

## Rules bắt buộc
1. LUÔN search("keyword") trước khi create task mới
2. LUÔN set assignee khi create task
3. Tạo multiple tasks trong 1 lượt khi có thể (parallel execution)
4. Dùng blocked_by khi tasks có dependency
5. Khi agent báo blocked → báo ngay lên Dẹo, không để tắc

## Output format
- Mọi output content từ L2 agents phải dạng .md
- office-agent (L3) sẽ format thành file cuối

## Agents và specialties
- finance-agent:        kế toán, lương, thuế, BCTC
- legal-agent:          hợp đồng, pháp chế
- hr-agent:             nhân sự, tuyển dụng, chấm công
- crm-agent:            khách hàng, leads, sales
- project-manager-agent: quản lý dự án, milestone, tiến độ
- marketing-agent:      content, chiến dịch, social
- researcher-agent:     nghiên cứu, phân tích thị trường
- it-dev-agent:         code, deploy, system
- office-agent:         format file (docx/xlsx/pptx) — LUÔN là bước cuối
```

### 7.3 office-agent (L3) — SOUL.md

```markdown
# Office Agent — File Formatter

Bạn là Office Agent, L3 Specialist.
Chuyên môn DUY NHẤT: nhận .md content → tạo file đẹp, chuẩn.

## KHÔNG làm
- Không phân tích, không thay đổi nội dung
- Không tự ý thêm/bớt data

## QUY TRÌNH BẮT BUỘC
1. vault_search("brand rules") → lấy màu, font, margin công ty
2. vault_search("template {loại file}") → lấy template chuẩn
3. Dùng Claude Code + officecli để tạo file
4. Save vào đúng path: 04_OUTPUTS/{department}/YYYY-MM/
5. Report file path về cho office-admin-agent

## File naming
Format: YYYY-MM-DD_{dept}_{type}_{subject}.{ext}
Ví dụ: 2026-05-25_ke-toan_bang-luong_thang-05.xlsx

## Docx chuẩn VN
- Font: Times New Roman 13pt (nội dung), 14pt bold (tiêu đề)
- Lề: trên 2cm, dưới 2cm, trái 3cm, phải 2cm
- Số văn bản: [MÃ-LOẠI]-[NĂM]-[SỐ] (VD: HĐLĐ-2026-001)

## Xlsx chuẩn
- Header: bold, background #E3F2FD
- Số tiền: #,##0 VND
- Ngày: DD/MM/YYYY
- Summary sheet nếu có nhiều data
```

### 7.4 it-dev-agent (L2) — SOUL.md

```markdown
# IT Dev Agent — System Builder

Senior Full-Stack Developer với Claude Code CLI.

## Stack
Backend: Go 1.26, TypeScript/Node.js, Python
Frontend: React 19, Next.js, Tailwind CSS
Database: PostgreSQL 18, SQLite
Infrastructure: Docker, Cloudflare, Linux VPS

## Tools
- acp provider (Claude Code) → execute code, bash, git
- sandbox mode → test trước khi deploy
- write_file, read_file → edit codebase

## Quy trình
1. Đọc hiểu yêu cầu → vault_search("architecture docs")
2. Viết code → test trong sandbox
3. Deploy → verify → report
4. KHÔNG deploy production mà không notify Vincent

## Repositories
- C:\goclaw\     → GoClaw gateway source
- C:\Users\Admin\deo-enterprise-os\ → Business OS
```

---

## 8. VAULT DOCUMENT STRUCTURE

### 8.1 Tài liệu cần upload ngay (ưu tiên cao)

```
Scope: team (chia sẻ toàn Dẹo Enterprise Team)

01_company/:
  [x] company-info.md        → Thông tin công ty, địa chỉ, MST
  [x] org-chart.md           → Sơ đồ tổ chức, ai phụ trách gì
  [ ] active-projects.md     → PRJ-001, PRJ-002 và context
  [ ] policies/luong.md      → Chính sách lương, thưởng

02_templates/:
  [ ] ke-toan/bang-luong.md  → Cấu trúc bảng lương, cột, công thức BHXH
  [ ] ke-toan/phieu-thu-chi.md
  [ ] legal/hop-dong-lao-dong.md
  [ ] legal/hop-dong-dich-vu.md
  [ ] hr/onboarding-checklist.md
  [ ] brand/design-rules.md  → Màu sắc, font, logo path

03_rules/:
  [ ] bhxh-2025.md           → % BHXH/BHYT/BHTN năm 2025
  [ ] thue-tncn.md           → Biểu thuế 9 bậc lũy tiến
  [ ] thue-gtgt.md           → Quy định GTGT, hạn nộp
  [ ] bo-luat-lao-dong.md    → Key articles cần nhớ
```

### 8.2 Cách upload nhanh nhất

```
Option 1: Nhắn Dẹo qua Telegram:
  "Tạo file vault: 02_templates/ke-toan/bang-luong.md
   Nội dung: [paste content]"
  → Dẹo write_file → VaultSyncWorker auto-index

Option 2: Dashboard → Knowledge Vault → Upload
  → Chọn agent: deo hoặc team scope
  → Upload .md files

Option 3: Batch upload qua API (nếu nhiều files)
  POST /v1/agents/{agentID}/vault/documents
```

---

## 9. CRON JOBS & HEARTBEAT

```json
Cron schedule (timezone: Asia/Ho_Chi_Minh):

"bang-luong-thang":     "0 8 25 * *"    → finance-agent
  "Tổng hợp bảng lương tháng này..."

"kiem-tra-hop-dong":    "0 9 1 * *"     → legal-agent
  "Kiểm tra hợp đồng hết hạn trong 30 ngày..."

"bao-cao-tuan":         "0 7 * * 1"     → project-manager-agent
  "Báo cáo tiến độ dự án tuần qua..."

"morning-briefing":     "0 8 * * 1-5"   → deo
  "Morning briefing: tasks overdue, meetings hôm nay..."

"digest-cuoi-ngay":     "0 17 * * 1-5"  → deo
  "Tổng hợp hoạt động hôm nay..."

Heartbeat:
  finance-agent:          interval: 480 min  → kiểm tra công nợ
  hr-agent:               interval: 1440 min → sinh nhật NV, HĐ hết hạn
  project-manager-agent:  interval: 480 min  → task quá deadline
```

---

## 10. WEBAPP INTEGRATION

### 10.1 API Endpoints (GoClaw → Webapp)

```javascript
// Chat với agent
POST /v1/chat/completions
  Authorization: Bearer goclaw_sk_<user_key>
  X-GoClaw-User-Id: vincent-tung
  body: { model: "agent:deo", messages: [...], stream: true }

// Đọc task board
GET /v1/teams/{team_id}/tasks?status=active
  Authorization: Bearer goclaw_sk_<manager_key>
  X-GoClaw-User-Id: nguyen-manager

// Vault search (dashboard hiển thị docs)
POST /v1/agents/{agentID}/vault/search
  body: { query: "hợp đồng", scope: "team", max_results: 10 }

// Knowledge Graph (org chart visualization)
GET /v1/agents/{agentID}/kg/graph?user_id=vincent-tung

// WebSocket realtime events
ws://localhost:18790/ws
  → team.task.created, team.task.completed, agent.status
```

### 10.2 Webapp Pages Priority

```
/dashboard          → KPI cards, activity feed, agent status
/tasks              → Task board (Kanban), filter by agent/project
/chat               → Chat interface per user role
/files              → Browse 04_OUTPUTS/, download files
/vault              → Knowledge base browser
/audit              → Audit trail (every action logged)
```

---

## 11. DEPLOYMENT CHECKLIST

### Phase 1 — Hoàn thành tuần này
- [x] GoClaw chạy trên Xeon (:18790)
- [x] @condeobot Telegram connected
- [x] 13 agents configured trong DB
- [x] Dẹo Enterprise Team active
- [x] Hooks disabled (tạm thời)
- [ ] Fix channel_contacts: user_id "vincent-tung" + metadata
- [ ] Viết SOUL.md cho deo, office-admin-agent, office-agent
- [ ] Upload 5 vault templates cơ bản
- [ ] Test full delegation: Vincent → Dẹo → L1 → L2 → L3

### Phase 2 — Tuần sau
- [ ] Run migration deo.* schema trên VPS Postgres
- [ ] Kết nối Postgres MCP: GoClaw → VPS DB
- [ ] Cài officecli MCP server
- [ ] Cài markitdown MCP server
- [ ] Test: finance-agent query DB + tạo báo cáo .md
- [ ] Test: office-agent nhận .md → output xlsx

### Phase 3 — 2 tuần sau
- [ ] Tạo tenants cho từng công ty
- [ ] Webapp Next.js kết nối GoClaw API
- [ ] Dashboard: task board realtime via WebSocket
- [ ] Human worker registration flow
- [ ] Cron jobs bật

---

## 12. SECURITY & AUDIT

```
Mọi action đều logged:
  deo.audit_events: actor_type, actor_id, action, metadata

API Key scopes:
  Vincent (owner):    gateway token → cross-tenant
  Manager:            operator.write → 1 tenant
  Staff:              operator.read → 1 agent

Data isolation:
  GoClaw: tenant_id enforced trên 40+ tables (fail-closed)
  Business DB: company_id enforced trên mọi query

PII protection:
  pii-redactor hook active: auto-redact email/phone trong messages
  Sensitive data: AES-256-GCM encrypted trong llm_providers
```

---

*Dẹo Enterprise OS v3.0 — GoClaw Edition*
*Cập nhật: 2026-05-14 | Vincent Tung*
