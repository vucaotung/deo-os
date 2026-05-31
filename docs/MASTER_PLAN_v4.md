# Dẹo Enterprise OS — Master Plan v4.1

> **Phiên bản:** 4.1 (Antigravity Native Edition)
> **Ngày cập nhật:** 31/05/2026
> **Tác giả:** Vincent Tung
> **Trục lõi:** Google Antigravity SDK · Hybrid DB (SQLite + Sheets) · Single VPS
> **Mô hình cốt lõi:** Projects Isolation ➔ Implementation Plan ➔ Subagents ➔ Artifacts

## 1. TRIẾT LÝ HỆ THỐNG VÀ 3 TRỤ CỘT MỚI
Hệ thống giữ nguyên mục tiêu cốt lõi: AI không trả lời chung chung, AI thực thi công việc thực tế (tính lương, soạn hợp đồng, lọc CV). Tuy nhiên, thay vì phân việc thủ công qua Database (như v3), Antigravity v4 vận hành qua 3 trụ cột mới:
 1. **Projects (Không gian biệt lập):** Thay thế cho việc dùng thư mục `/workspace/` tĩnh và cột `company_id` trong SQL. Mỗi Công ty (Tenant) hoặc Chiến dịch lớn là một Project. Agent chạy trong Project nào chỉ có Context và Database của Project đó.
 2. **Implementation Plan (Kế hoạch thực thi):** AI L1 không code/chạy ngay lập tức. Nó tự động sinh ra một Kế hoạch (Plan) gồm các bước rõ ràng. Human (Vincent) có thể Review/Approve plan này trước khi Subagents (L2) thực sự tiêu tốn tài nguyên chạy.
 3. **Artifacts (Sản phẩm đầu ra thông minh):** Output (`.md`, `.xlsx`) không còn là các file ném vào thư mục `/04_OUTPUTS/` chờ đồng bộ. Chúng trở thành Artifacts — các đối tượng có phiên bản (version-controlled), có thể preview trực tiếp trên Webapp, và AI có thể tự động chỉnh sửa lại (edit/patch) dựa trên feedback của sếp.

## 2. KIẾN TRÚC HẠ TẦNG (SINGLE VPS)
Hệ thống hội tụ toàn bộ lên 1 VPS duy nhất, loại bỏ máy Xeon làm Gateway.
```text
VPS (Ubuntu 24.04 - Production):
│
├── Lõi Điều Phối: Antigravity SDK (Python)
│   ├── Telegram/Zalo Webhooks
│   ├── Agent Runtime (L0 Orchestrator)
│   └── System Tools (Custom Python Functions)
│
├── Project Workspaces (Cách ly môi trường)
│   ├── Project: Deo_Enterprise (Cty Mẹ)
│   │   ├── SQLite DB (Business Data)
│   │   ├── Context/Rules (Thay thế Vault)
│   │   └── Artifacts Store
│   └── Project: Cty_A (Tenant A) ...
│
├── Tầng Hiển Thị & Báo Cáo (Human UI)
│   ├── Dẹo Webapp (Next.js) :3000
│   └── Google Sheets API (Báo cáo trực quan cho C-Level)
│
└── Rclone Sync Service 
    └── Đẩy Final Artifacts lên Google Drive
```

## 3. PHÂN CẤP AGENT & QUYỀN HẠN (CODE-DEFINED)
Cấu trúc L0 → L3 được giữ nguyên, nhưng loại bỏ hoàn toàn các file `SOUL.md`, `TOOLS.md`... để dùng Config Objects của Antigravity, kết hợp Declarative Policies.
 * **L0 (Dẹo - Main Orchestrator):** Tiếp nhận yêu cầu từ Vincent (ID: 7293498822). Xác định context thuộc Project nào.
 * **L1 (Office Admin - Team Lead):** KHÔNG tự làm việc. Nhận yêu cầu từ L0, phân rã thành **Implementation Plan**. Sinh ra (Spawn) các Subagents để chạy các bước trong Plan.
 * **L2 (Specialists):** Các chuyên gia (finance-agent, legal-agent, v.v.). Chỉ được phân quyền (Policies) query SQLite DB và xử lý logic, output ra JSON/Data thô.
 * **L3 (Office Agent - Formatter):** Chuyên tạo **Artifacts**. Nhận data thô, format thành Docx/Xlsx chuẩn Brand của Project, sinh ra Artifact có URL để sếp tải. KHÔNG phân tích nội dung.

## 4. LUỒNG THỰC THI CHUẨN (WORKFLOW V4.1)
Kịch bản: *Vincent nhắn Telegram: "Làm bảng lương tháng 5 cho công ty mẹ".*

### Bước 1: Routing & Context (L0)
 * **L0 (Dẹo)** nhận tin. Nhận diện user_id = vincent-tung.
 * Dẹo thiết lập môi trường chạy (Runtime) trỏ thẳng vào **Project: Deo_Enterprise**.
 * Dẹo delegate lệnh xuống cho **L1**.

### Bước 2: Sinh Kế hoạch (Implementation Plan - L1)
 * **L1 (office-admin)** dùng SDK tạo ra một đối tượng Implementation Plan gồm 3 bước:
   1. Spawn hr-agent query SQLite lấy số ngày công.
   2. Spawn finance-agent tính toán lương, áp dụng rule Thuế/BHXH.
   3. Spawn office-agent tạo Artifact Excel.
 * *(Tuỳ chọn)* Plan này được đẩy lên Telegram/Webapp: *"Sếp có duyệt quy trình này không?"*. Vincent bấm Approve.

### Bước 3: Thực thi Bất đồng bộ (Subagents - L2)
 * L1 kích hoạt agent.spawn("hr-agent") và agent.spawn("finance-agent") (nếu các task song song được).
 * Các L2 Agent gọi Tool (Custom Python Tool) query vào file SQLite của Project, tính toán cực nhanh, trả về một Pydantic JSON Object cho L1.

### Bước 4: Đóng gói Sản phẩm (Artifacts - L3)
 * L1 spawn office-agent (L3). L3 gọi Tool create_artifact_xlsx().
 * Một **Artifact** mang tên Bảng_Lương_T5_v1 được sinh ra trong Project.
 * L3 gọi tool gdrive_upload chạy lệnh rclone copy đẩy Artifact này lên thư mục `/Dẹo Enterprise OS/Kế_Toán/Bang_Luong/2026-05/`.

### Bước 5: Phản hồi
 * L0 báo cáo qua Telegram: *"✅ Bảng lương T5 xong. Link File: [URL_Drive] | Link preview Webapp: [URL_Artifact]"*.

## 5. DATABASE & STORAGE SCHEMA (HYBRID MODEL)
Hệ thống kết hợp sự tốc độ của SQLite (Agent dùng) và tính trực quan của Google Sheets/Drive (Người dùng).

### 5.1 Project SQLite Database (Dành cho L2/L3 query)
Mỗi Project có một file `.db` riêng (Cách ly dữ liệu 100%).
```sql
-- deo_workers, deo_employees, deo_payroll, deo_contracts, deo_invoices
-- (Giữ nguyên schema chuẩn từ v3, nhưng loại bỏ cột company_id vì đã được cách ly bằng file db của Project).
```
*Ghi chú Audit:* Bảng `audit_events` được ghi tự động bằng Antigravity **Lifecycle Hooks** (chặn ở tầng mạng). Agent không thể tự ý xóa log của chính nó.

### 5.2 Google Sheets & Google Drive (Tầng hiển thị - Artifacts)
 * **Google Sheets:** Khi Human cần xem báo cáo nhanh, finance-agent có thể gọi tool `export_to_sheet()` để đè dữ liệu lên một file Sheet cố định (Dùng làm Dashboard cho ban lãnh đạo).
 * **Google Drive (rclone):** Artifacts (Docx, Xlsx) sinh ra từ L3 được đồng bộ 1 chiều lên Drive làm bản Final (SSOT).

## 6. CẤU TRÚC THƯ MỤC SOURCE CODE (TRÊN VPS)
Bỏ qua cấu trúc thư mục phức tạp của GoClaw, codebase của Antigravity SDK tinh gọn như sau:
```text
/app/deo-os/
├── core/
│   ├── orchestrator.py        ← Khởi tạo L0 và nhận Webhook
│   ├── subagents.py           ← Logic định nghĩa các L1, L2, L3 (Thay thế SOUL.md)
│   ├── tools.py               ← Hàm Python (SQL query, rclone trigger, format excel)
│   └── hooks.py               ← Lifecycle Hooks (Audit log, Security)
│
├── projects/                  ← Quản lý các Tenant/Company
│   ├── deo_enterprise/        
│   │   ├── db.sqlite          ← DB của công ty mẹ
│   │   ├── rules/             ← Context dạng text (Brand guideline, policies)
│   │   └── artifacts/         ← File xlsx, docx sinh ra chờ sync rclone
│   └── company_a/
│       └── ...
│
├── webapp/                    ← Next.js source code
│
├── scripts/
│   └── setup_rclone.sh        ← Cài đặt và mount Google Drive
│
└── main.py                    ← Entry point khởi chạy toàn bộ Hệ điều hành
```

## 7. LỘ TRÌNH TRIỂN KHAI (IMPLEMENTATION ROADMAP)
 * **Phase 1: Foundation (Tuần 1)**
   * Cài đặt Python 3.10+, Antigravity SDK trên VPS Ubuntu.
   * Setup SSH không mật khẩu (từ Xeon lên VPS) để AI `it-dev-agent` có thể tự deploy code.
   * Cài đặt và config rclone kết nối Google Drive (Remote name: `gdrive`).
 * **Phase 2: Project & Subagents (Tuần 2)**
   * Code file `subagents.py`: Định nghĩa Config, System Instructions, và Tools cho toàn bộ 13 agents.
   * Xây dựng luồng Implementation Plan cho quy trình đầu tiên: Tạo Hợp đồng Lao động.
 * **Phase 3: Database & Tools (Tuần 3)**
   * Viết file `tools.py` kết nối trực tiếp vào SQLite để đọc list NV, lương.
   * Viết Tool xuất Artifact và trigger lệnh `rclone copy`.
 * **Phase 4: Webapp & Launch (Tuần 4)**
   * Dựng giao diện Next.js đọc thông tin Artifacts và hiển thị trạng thái Agents.
   * Bật Cron jobs của Antigravity (`bang-luong-thang`, `kiem-tra-hop-dong`).

*V4.1 không chỉ là một chatbot kết nối database, nó là một nhà máy tự động hóa hoàn chỉnh.*
