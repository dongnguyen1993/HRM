# HRM Enterprise - Quy Chuẩn Phát Triển & AI Collaboration Rules

Tài liệu này là **bộ quy chuẩn tối cao** dành cho lập trình viên và các AI coding assistant (Antigravity, Cursor, Copilot, ChatGPT...) khi cùng tham gia phát triển dự án HRM Enterprise. Tất cả các prompt và mã nguồn mới phải tuân thủ nghiêm ngặt các quy tắc sau.

---

## 1. Kiến Trúc Phân Hệ 3+1 Domains (BẮT BUỘC)
Hệ thống đã được quy hoạch thành 4 Domain độc lập và rõ ràng. Tuyệt đối **KHÔNG** quay lại cấu trúc thư mục hoặc routing lộn xộn cũ:

| Domain | Tiền tố | Đường dẫn Route | Mã Menu | Phạm vi chức năng |
|:---|:---:|:---:|:---:|:---|
| **ESS** | `ESS_*` | `/ess/*` | `1000..1005` | Cổng Tự Phục Vụ Nhân Viên (User Overview, Lịch làm việc, Bảng công, Đăng ký suất ăn, Phiếu lương) |
| **HR**  | `HR_*`  | `/hr/*`  | `2000..2010` | Quản Trị Nhân Sự (Phòng ban, Hợp đồng, Nghỉ phép, Bảng lương, Ca kíp, Chấm công BioStar, OT, Báo cáo) |
| **GA**  | `GA_*`  | `/ga/*`  | `3000..3003` | Quản Trị Hành Chính (Quản lý suất ăn Canteen, Lịch nhà máy & ca ăn, Danh mục phòng ban đặt cơm) |
| **SYS** | `SYS_*` | `/sys/*` | `4000..4009` | Quản Trị Hệ Thống (Người dùng, Phân quyền, Quản lý Menu, Mã dùng chung, Audit Logs, Thông báo, Thiết bị) |

---

## 2. Quy Chuẩn Cơ Sở Dữ Liệu & Bảng (Database Schema)
1. **Tiền tố bảng bắt buộc:** Tất cả các bảng CSDL phải có tiền tố Domain:
   - Phân hệ GA: `GA_MealOrders`, `GA_WorkCalendar`, `GA_Departments`.
   - Phân hệ HR: `HR_Departments`, `HR_LaborContracts`, `HR_LeaveTypes`, `HR_PayrollPeriods`, `HR_ShiftSetup`, `HR_TimeOffRequests`, `HR_OvertimeRegistrations`, `HR_BiostarMachineRecords`, `HR_WorkSummaries`, `HR_WorkTimeReports`...
   - Phân hệ SYS: `SYS_Users`, `SYS_ProgramMenus`, `SYS_AuthorGroups`, `SYS_AuthorGroupMapping`, `SYS_CommonCodes`, `SYS_AuditLogs`, `SYS_SignInLogs`, `SYS_Announcements`, `SYS_NotificationEvents`, `SYS_DeviceSetups`...
   - Phân hệ ESS: Dùng chung bảng dữ liệu từ các domain nghiệp vụ với view cá nhân hóa.
   - **CẤM:** Không được tạo hoặc query vào các tên bảng cũ không có tiền tố (ví dụ cấm dùng: `MealOrders`, `WorkCalendar`, `Departments`, `ProgramMenus`...).
2. **Bảng Menu & Phân Quyền (`SYS_ProgramMenus` & `SYS_AuthorGroupMapping`):**
   - Bảng `SYS_ProgramMenus` đã được chuẩn hóa cố định 31 màn hình với `ProgramId` chạy tuần tự từ **1 đến 31** (Identity tiếp theo bắt đầu từ **32**).
   - Tuyệt đối **KHÔNG TRUNCATE** bảng `SYS_ProgramMenus` hay `SYS_AuthorGroupMapping`. Nếu cần bổ sung màn hình mới, sử dụng câu lệnh `INSERT` có `SortOrder` theo đúng domain.
3. **Tiếng Việt & Bảng mã Unicode:**
   - Mọi chuỗi tiếng Việt Unicode có dấu trong các câu lệnh SQL bắt buộc phải có tiền tố `N'...'` (Ví dụ: `N'Quản lý suất ăn'`, `N'Ca ngày'`).
   - Mọi script PowerShell kết nối CSDL hoặc đọc file phải luôn có:
     ```powershell
     [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
     $OutputEncoding = [System.Text.Encoding]::UTF8
     ```
   - Luôn thực thi SQL qua script chuẩn: `d:\HRM\scripts\execute_sql.ps1`.

---

## 3. Quy Chuẩn Backend (.NET 8 & Dapper)
1. **Cấu trúc thư mục theo Domain:**
   - Mã nguồn Backend phân chia theo Domain tại: `HRM.Backend/Domains/{DOMAIN}/` (Ví dụ: `Domains/GA/`, `Domains/HR/`, `Domains/SYS/`, `Domains/ESS/`).
   - Mỗi Domain gồm các thư mục con: `Controllers/`, `Services/`, `Repositories/`, `Queries/`.
2. **Quy tắc Routing API:**
   - Mọi API mới phải bắt đầu bằng `/api/{domain-lowercase}/...` (Ví dụ: `/api/ga/meal-orders`, `/api/ga/work-calendar`, `/api/ga/departments`).
   - Giữ lại các alias cũ nếu cần tương thích ngược cho mobile/clients cũ.
3. **Dapper SQL:**
   - Toàn bộ câu lệnh SQL thuần được lưu tại file riêng: `HRM.Backend/Domains/{DOMAIN}/Queries/{FeatureName}Queries.sql`.
   - Trong SQL, luôn chỉ định rõ schema và tên bảng chuẩn: `dbo.GA_MealOrders`, `dbo.GA_WorkCalendar`...
4. **Kiểm tra Phân quyền (Authorization):**
   - Các API nghiệp vụ cần bảo vệ quyền phải được gán attribute chuẩn:
     - Màn hình Suất ăn GA: `[HasPermission("3001_GA_MEAL_MANAGEMENT")]` (hỗ trợ alias `[HasPermission("MEAL_MANAGEMENT")]`)
     - Màn hình Lịch làm việc: `[HasPermission("3002_GA_WORK_CALENDAR")]` (hỗ trợ alias `[HasPermission("WORK_CALENDAR")]`)
     - Màn hình Phòng ban GA: `[HasPermission("3003_GA_DEPARTMENTS")]`

---

## 4. Quy Chuẩn Frontend (React / Ant Design / Vite / Umi)
1. **Cấu trúc thư mục UI:**
   - Mỗi phân hệ đặt trong: `HRM.Frontend/src/pages/{DOMAIN}/`
   - Phân hệ GA gồm:
     - `src/pages/GA/MealManagement/` (Quản lý suất ăn, chốt cơm Canteen)
     - `src/pages/GA/WorkCalendar/` (Lịch làm việc nhà máy & suất ăn)
     - `src/pages/GA/DepartmentList/` (Danh sách phòng ban đặt cơm)
2. **Gọi API:**
   - Mọi service gọi API thông qua reverse proxy: `/api/ga/...`.
3. **React Hooks & Coding Style:**
   - Tuân thủ nghiêm ngặt thứ tự gọi React Hooks (không đặt Hook sau `if (condition) return ...`).
   - Luôn dọn dẹp các biến/import không sử dụng để tránh lỗi pre-commit linter.

---

## 5. Quy Chuẩn Git & Đồng Bộ GitHub (NGHIÊM NGẶT - GIT SUBMODULE)

Dự án HRM Enterprise áp dụng mô hình **Git Submodules** (gồm 3 repository độc lập: Backend, Frontend và Root HRM). Do đó, việc commit và push phải tuân thủ nghiêm ngặt các quy tắc sau:

### 5.1. Nguyên tắc vàng
1. **TUYỆT ĐỐI KHÔNG tự ý chạy `git push`:** AI chỉ được phép thực hiện commit/push khi có lệnh rõ ràng từ lập trình viên (Ví dụ: *"hãy commit và push code lên github"*).
2. **Bản chất Submodule:** Thư mục gốc `HRM` chỉ lưu con trỏ commit hash của `HRM.Backend` và `HRM.Frontend`. Nếu bạn commit ở Root trước khi push Submodule, người khác kéo về sẽ bị lỗi **vỡ liên kết Submodule (Submodule pointer mismatch)**.

### 5.2. Thứ tự 3 bước Commit & Push bắt buộc:
Luôn thực hiện từ **thư mục con (Submodule)** rồi mới đến **thư mục cha (Root)**:

```bash
# BƯỚC 1: Commit & Push Backend (nếu có chỉnh sửa Backend)
cd d:\HRM\HRM.Backend
git status
git add .
git commit -m "feat(GA): bổ sung API và Dapper SQL cho phân hệ suất ăn"
git push origin main

# BƯỚC 2: Commit & Push Frontend (nếu có chỉnh sửa Frontend)
cd d:\HRM\HRM.Frontend
git status
git add .
git commit -m "feat(GA): hoàn thiện giao diện màn hình quản lý suất ăn"
git push origin main

# BƯỚC 3: Cập nhật con trỏ Submodule tại thư mục Root HRM
cd d:\HRM
git status
git add HRM.Backend HRM.Frontend scripts/ AGENTS.md
git commit -m "chore: đồng bộ submodule pointers và tài liệu phân hệ GA"
git push origin main
```

### 5.3. Quy tắc Pull Code khi bắt đầu ngày làm việc:
Đồng nghiệp khi bắt đầu làm việc hoặc kéo code mới về máy cần chạy đúng 2 lệnh:
```bash
git pull origin main
git submodule update --init --recursive
```

### 5.4. Quy chuẩn thông điệp Commit (Đơn giản & Trực quan - BẮT BUỘC):
Quy ước đặt tên commit: **`[TÊN_DOMAIN]: [Hành động & Mô tả]`** (Viết liền trước dấu `:`, cách 1 space sau dấu `:`).

Cách đặt này giúp toàn team nhìn vào lịch sử commit trên GitHub là nhận diện ngay phân hệ bị tác động:
- `GA: Thêm chức năng chốt cơm Canteen theo ngày`
- `GA: Sửa lỗi tính sai suất ăn ca đêm`
- `HR: Tích hợp dữ liệu quẹt thẻ máy chấm công BioStar`
- `HR: Sửa công thức tính phụ cấp thâm niên bảng lương`
- `ESS: Tối ưu giao diện xem phiếu lương trên điện thoại`
- `SYS: Bổ sung màn hình cấu hình thiết bị chấm công`
- `CHORE: Đồng bộ con trỏ submodule và tài liệu dự án` (Dùng cho thư mục Root HRM hoặc cập nhật script)


---

## 6. Mẫu Prompt Chuẩn Dành Cho Đồng Nghiệp Khi Dùng AI
Khi đồng nghiệp bắt đầu prompt AI để code tính năng mới (ví dụ làm module GA), hãy copy đoạn ngữ cảnh mẫu này vào đầu phiên làm việc:

```markdown
Tôi đang phát triển phân hệ GA (Quản Trị Hành Chính) cho dự án HRM Enterprise.
Hệ thống đã được chuẩn hóa theo các quy tắc trong file `AGENTS.md`:
- Phân hệ GA gồm 3 bảng CSDL: GA_MealOrders, GA_WorkCalendar, GA_Departments.
- Backend nằm tại: `HRM.Backend/Domains/GA/` (API route: `/api/ga/...`).
- Dapper SQL nằm tại: `HRM.Backend/Domains/GA/Queries/*.sql`.
- Frontend nằm tại: `HRM.Frontend/src/pages/GA/`.
- Phân quyền sử dụng các mã: 3001_GA_MEAL_MANAGEMENT, 3002_GA_WORK_CALENDAR, 3003_GA_DEPARTMENTS.
- Tuyệt đối không tự ý chạy git push. Mọi câu lệnh SQL tiếng Việt phải có tiền tố N'...'.

Yêu cầu hiện tại của tôi: [Mô tả tính năng bạn muốn AI hỗ trợ viết]
```



