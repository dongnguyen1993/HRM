# HRM Enterprise - Quy Chuẩn Phát Triển & AI Collaboration Rules

Tài liệu này là **bộ quy chuẩn tối cao** dành cho lập trình viên và các AI coding assistant (Antigravity, Cursor, Copilot, ChatGPT...) khi cùng tham gia phát triển dự án HRM Enterprise. Tất cả các prompt và mã nguồn mới phải tuân thủ nghiêm ngặt các quy tắc sau.

---

## 1. Kiến Trúc Phân Hệ 3+1 Domains & Chuẩn Hóa 1-1-1-1-1 (BẮT BUỘC)

Hệ thống đã được quy hoạch thành 4 Domain độc lập và rõ ràng. Toàn bộ mã nguồn tuân thủ nghiêm ngặt cấu trúc **1 UI - 1 Controller - 1 Service - 1 Repository - 1 SQL Query**:

| Domain | Tiền tố | Đường dẫn Route UI | Đường dẫn API Backend | Mã Menu | Phạm vi chức năng |
|:---|:---:|:---:|:---:|:---:|:---|
| **ESS** | `ESS_*` | `/ess/*` | `/api/ess/*` | `1001..1005` | Cổng Tự Phục Vụ Nhân Viên (User Overview, Lịch làm việc, Bảng công, Đăng ký suất ăn, Phiếu lương) |
| **HR**  | `HR_*`  | `/hr/*`  | `/api/hr/*`  | `2001..2010` | Quản Trị Nhân Sự & Chấm Công (Phòng ban, Hợp đồng, Nghỉ phép, Bảng lương, Ca kíp, Chấm công BioStar, OT, Báo cáo) |
| **GA**  | `GA_*`  | `/ga/*`  | `/api/ga/*`  | `3001..3006` | Quản Trị Hành Chính (Suất ăn Canteen, Lịch nhà máy, Phòng ban đặt cơm, Đăng ký khách vào cổng, Duyệt khách, Kiểm soát Cổng) |
| **SYS** | `SYS_*` | `/sys/*` | `/api/sys/*` | `4001..4009` | Quản Trị Hệ Thống (Người dùng, Phân quyền, Quản lý Menu, Mã dùng chung, Audit Logs, Thông báo, Thiết bị) |

### Nguyên tắc liên kết 1-1-1-1-1:
Mỗi chức năng nghiệp vụ độc lập được thiết kế tương ứng qua 5 tầng khép kín:
1. **1 Giao diện UI Frontend:** `HRM.Frontend/src/pages/{DOMAIN}/{FeatureName}/`
2. **1 Bộ điều khiển Controller:** `HRM.Backend/Domains/{DOMAIN}/Controllers/{FeatureName}Controller.cs`
3. **1 Dịch vụ nghiệp vụ Service:** `HRM.Backend/Domains/{DOMAIN}/Services/{FeatureName}Service.cs`
4. **1 Kho lưu trữ dữ liệu Repository:** `HRM.Backend/Domains/{DOMAIN}/Repositories/{FeatureName}Repository.cs`
5. **1 Tệp truy vấn Dapper SQL:** `HRM.Backend/Domains/{DOMAIN}/Queries/{FeatureName}Queries.sql`

> [!IMPORTANT]
> **API Đơn Nhất (Direct API Call):** Frontend gọi trực tiếp 1 đường dẫn API duy nhất xuống Backend theo định dạng `/api/{domain-lowercase}/{feature}` (Ví dụ: `GET /api/ga/departments`, `POST /api/ga/meal-orders`, `GET /api/hr/departments`, `GET /api/sys/users`...). Tuyệt đối không qua các endpoint trung gian hoặc đặt sai Domain.

---

## 2. Quy Chuẩn Cơ Sở Dữ Liệu (Database Schema)

1. **35 Bảng nghiệp vụ chuẩn hóa có tiền tố Domain:**
   - Cơ sở dữ liệu đã dọn dẹp sạch toàn bộ 30 bảng cũ không có tiền tố. Hiện tại chỉ duy trì đúng **35 bảng chính thức** có tiền tố rõ ràng:
     - **Phân hệ GA:** `GA_Departments`, `GA_MealOrders`, `GA_WorkCalendar`, `GA_VisitorRegistrations`, `GA_VisitorDetails`.
     - **Phân hệ HR:** `HR_Departments`, `HR_LaborContracts`, `HR_LeaveTypes`, `HR_PayrollPeriods`, `HR_PayrollSalaryItem`, `HR_PayrollEmployeeMonthly`, `HR_PositionsRole`, `HR_PositionsGrade`, `HR_ShiftSetup`, `HR_TimeOffRequests`, `HR_OvertimeRegistrations`, `HR_BiostarMachineRecords`, `HR_WorkSummaries`, `HR_WorkTimeReports`...
     - **Phân hệ SYS:** `SYS_Users`, `SYS_UserGroupMapping`, `SYS_UserTokens`, `SYS_UserThemeSettings`, `SYS_UserAttachments`, `SYS_ProgramMenus`, `SYS_AuthorGroups`, `SYS_AuthorGroupMapping`, `SYS_CommonCodes`, `SYS_AuditLogs`, `SYS_SignInLogs`, `SYS_Announcements`, `SYS_NotificationEvents`, `SYS_Notifications`, `SYS_DeviceSetups`, `SYS_SystemSettings`...
     - **Phân hệ ESS:** Sử dụng chung dữ liệu bảo mật từ các domain nghiệp vụ với view cá nhân hóa qua `UserCode`.
   - **CẤM:** Tuyệt đối không tạo mới hoặc truy vấn vào các tên bảng cũ không có tiền tố (như `MealOrders`, `Departments`, `Users`, `ProgramMenus`...).

2. **Bảng Menu & Phân Quyền (`SYS_ProgramMenus` & `SYS_AuthorGroupMapping`):**
   - Bảng `SYS_ProgramMenus` đã được chuẩn hóa cố định 31 màn hình với `ProgramId` chạy tuần tự từ **1 đến 31** (Identity tiếp theo bắt đầu từ **32**).
   - Tuyệt đối **KHÔNG TRUNCATE** bảng `SYS_ProgramMenus` hay `SYS_AuthorGroupMapping`. Nếu bổ sung màn hình mới, sử dụng câu lệnh `INSERT` có `SortOrder` và kiểm tra điều kiện `IF NOT EXISTS`.

3. **Stored Procedures Chuẩn Hóa:**
   - Mọi Stored Procedure trong hệ thống bắt buộc truy vấn vào các bảng có tiền tố Domain:
     - `SP_GetDashboardAnalytics`: Truy vấn từ `dbo.SYS_Users`, `dbo.SYS_AuthorGroups`, `dbo.SYS_UserGroupMapping`.
     - `sp_CalculateTimesheetEngine`: Truy vấn từ `dbo.HR_WorkShifts`, `dbo.HR_MachineRecords`, `dbo.SYS_DeviceSetup`, `dbo.HR_WorkSummary`, `dbo.SYS_Users`.
   - Mọi script migration dọn dẹp CSDL và cập nhật SP được lưu trữ tập trung tại: `d:\HRM\scripts/`.

4. **Tiếng Việt & Bảng mã Unicode:**
   - Mọi chuỗi tiếng Việt Unicode có dấu trong các câu lệnh SQL bắt buộc phải có tiền tố `N'...'` (Ví dụ: `N'Quản lý suất ăn'`, `N'Ca ngày'`).
   - Mọi script PowerShell kết nối CSDL hoặc đọc file phải luôn có:
     ```powershell
     [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
     $OutputEncoding = [System.Text.Encoding]::UTF8
     ```
   - Thực thi SQL qua script chuẩn: `d:\HRM\scripts\execute_sql.ps1`.

---

## 3. Quy Chuẩn Backend (.NET 8 & Dapper)

1. **Cấu trúc thư mục theo Domain:**
   - Mã nguồn Backend phân chia theo Domain tại: `HRM.Backend/Domains/{DOMAIN}/` (`Domains/GA/`, `Domains/HR/`, `Domains/SYS/`, `Domains/ESS/`).
   - Mỗi Domain gồm đầy đủ các thư mục: `Controllers/`, `Services/`, `Repositories/`, `Queries/`.
2. **Quy tắc Routing RESTful API:**
   - Mọi API phải bắt đầu bằng `/api/{domain-lowercase}/...` (Ví dụ: `/api/ga/meal-orders`, `/api/ga/work-calendar`, `/api/ga/departments`, `/api/hr/departments`, `/api/sys/users`).
   - Cung cấp route gốc `[HttpGet]` cho các Controller tra cứu danh mục, tránh chỉ có route con gây lỗi 404/405 khi gọi REST chuẩn.
3. **Dapper SQL:**
   - Toàn bộ câu lệnh SQL thuần được lưu tại file riêng: `HRM.Backend/Domains/{DOMAIN}/Queries/{FeatureName}Queries.sql`.
   - Trong SQL, luôn chỉ định rõ schema và tên bảng chuẩn: `dbo.GA_MealOrders`, `dbo.GA_WorkCalendar`, `dbo.HR_Departments`...
4. **Kiểm tra Phân quyền (Authorization):**
   - Các API nghiệp vụ cần bảo vệ quyền phải được gán attribute chuẩn:
     - Màn hình Suất ăn GA: `[HasPermission("3001_GA_MEAL_MANAGEMENT")]`
     - Màn hình Lịch làm việc: `[HasPermission("3002_GA_WORK_CALENDAR")]`
     - Màn hình Phòng ban GA: `[HasPermission("3003_GA_DEPARTMENTS")]`
     - Màn hình Đăng ký khách (ESS): `[HasPermission("1006_ESS_VISITOR_REGISTRATION")]`
     - Màn hình Duyệt khách: `[HasPermission("3005_GA_VISITOR_APPROVAL")]`
     - Màn hình Cổng bảo vệ: `[HasPermission("3006_GA_VISITOR_GATE")]`

---

## 4. Quy Chuẩn Frontend (React / Ant Design / Vite / Umi)

1. **Cấu trúc thư mục UI:**
   - Mỗi phân hệ đặt trong: `HRM.Frontend/src/pages/{DOMAIN}/`
   - Phân hệ GA gồm:
     - `src/pages/GA/MealManagement/` (Quản lý suất ăn, chốt cơm Canteen)
     - `src/pages/GA/WorkCalendar/` (Lịch làm việc nhà máy & suất ăn)
     - `src/pages/GA/DepartmentList/` (Danh sách phòng ban đặt cơm)
     - `src/pages/GA/VisitorApproval/` (Duyệt đăng ký khách - Phụ trách: `huungociter`)
     - `src/pages/GA/VisitorGate/` (Kiểm soát cổng bảo vệ - Phụ trách: `huungociter`)
   - Phân hệ ESS gồm:
     - `src/pages/ESS/UserOverview/` (User Overview - 1001)
     - `src/pages/ESS/WorkSchedule/` (Lịch làm việc của tôi - 1002)
     - `src/pages/ESS/DailyWorkTime/` (Bảng công hàng ngày - 1003)
     - `src/pages/ESS/MealOrder/` (Đăng ký suất ăn - 1004)
     - `src/pages/ESS/MyPayslip/` (Phiếu lương của tôi - 1005)
     - `src/pages/ESS/VisitorRegistration/` (Đăng ký khách vào cổng - 1006 - Phụ trách: `huungociter`)
2. **Gọi API:**
   - Mọi service gọi API thông qua reverse proxy: `/api/{domain-lowercase}/...`.
3. **Dọn dẹp code dư thừa:**
   - Đã loại bỏ hoàn toàn các file mock không dùng (`mock/userAPI.ts`), các trang dynamic không dùng (`DynamicScreen`), và module HRM cũ (`src/pages/Hrm/...`).
   - Mọi component mới phải đảm bảo thứ tự React Hooks chuẩn và không import dư thừa.

---

## 5. Quy Chuẩn Git & Đồng Bộ GitHub (NGHIÊM NGẶT - GIT SUBMODULE)

Dự án HRM Enterprise áp dụng mô hình **Git Submodules** (gồm 3 repository độc lập: Backend, Frontend và Root HRM). Do đó, việc commit và push phải tuân thủ nghiêm ngặt các quy tắc sau:

### 5.1. Nguyên tắc vàng
1. **TUYỆT ĐỐI KHÔNG tự ý chạy `git push`:** AI chỉ được phép thực hiện commit/push khi có lệnh rõ ràng từ lập trình viên (Ví dụ: *"hãy commit và push code lên github"*).
2. **Bản chất Submodule:** Thư mục gốc `HRM` chỉ lưu con trỏ commit hash của `HRM.Backend` và `HRM.Frontend`. Nếu commit ở Root trước khi push Submodule, người khác kéo về sẽ bị lỗi **vỡ liên kết Submodule (Submodule pointer mismatch)**.

### 5.2. Thứ tự 3 bước Commit & Push bắt buộc:
Luôn thực hiện từ **thư mục con (Submodule)** rồi mới đến **thư mục cha (Root)**:

```bash
# BƯỚC 1: Commit & Push Backend (nếu có chỉnh sửa Backend)
cd d:\HRM\HRM.Backend
git status
git add .
git commit -m "[BACKEND]: Cập nhật Dapper SQL, Controller và chuẩn hóa domain"
git push origin main

# BƯỚC 2: Commit & Push Frontend (nếu có chỉnh sửa Frontend)
cd d:\HRM\HRM.Frontend
git status
git add .
git commit -m "[FRONTEND]: Chuẩn hóa API service, dọn dẹp code thừa và hoàn thiện giao diện"
git push origin main

# BƯỚC 3: Cập nhật con trỏ Submodule tại thư mục Root HRM
cd d:\HRM
git status
git add HRM.Backend HRM.Frontend scripts/ AGENTS.md
git commit -m "CHORE: Đồng bộ submodule pointers, cập nhật quy chuẩn kiến trúc và scripts CSDL"
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

Ví dụ:
- `[GA]: Thêm chức năng chốt cơm Canteen theo ngày`
- `[GA]: Sửa lỗi tính sai suất ăn ca đêm`
- `[HR]: Tích hợp dữ liệu quẹt thẻ máy chấm công BioStar`
- `[HR]: Chuẩn hóa bảng công tổng hợp theo ca kíp`
- `[ESS]: Cập nhật hạn mức nghỉ phép cá nhân và phiếu lương`
- `[SYS]: Cập nhật danh sách 31 menu chương trình và nhóm quyền`
- `CHORE: Đồng bộ con trỏ submodule và tài liệu dự án` (Dùng cho thư mục Root HRM hoặc cập nhật script)

---

## 6. Mẫu Prompt Chuẩn Dành Cho Đồng Nghiệp (`huungociter`) Khi Dùng AI
Khi `huungociter` bắt đầu prompt AI để code tính năng mới cho module GA, hãy copy đoạn ngữ cảnh mẫu này vào đầu phiên làm việc:

```markdown
Tôi là huungociter, phụ trách phát triển phân hệ GA (Quản Trị Hành Chính) cho dự án HRM Enterprise.
Hệ thống đã được chuẩn hóa theo các quy tắc trong file `AGENTS.md`:
- Phân hệ GA gồm các bảng CSDL: GA_MealOrders, GA_WorkCalendar, GA_Departments, GA_VisitorRegistrations, GA_VisitorDetails.
- Backend nằm tại: `HRM.Backend/Domains/GA/` (API route: `/api/ga/...`).
- Dapper SQL nằm tại: `HRM.Backend/Domains/GA/Queries/*.sql`.
- Frontend nằm tại: `HRM.Frontend/src/pages/GA/` (và view cá nhân `src/pages/ESS/VisitorRegistration/`).
- Phân quyền sử dụng các mã: 1006_ESS_VISITOR_REGISTRATION, 3001_GA_MEAL_MANAGEMENT, 3002_GA_WORK_CALENDAR, 3003_GA_DEPARTMENTS, 3005_GA_VISITOR_APPROVAL, 3006_GA_VISITOR_GATE.
- Tuyệt đối không tự ý chạy git push. Mọi câu lệnh SQL tiếng Việt phải có tiền tố N'...'.
- QUAN TRỌNG: Nếu yêu cầu của tôi có tác động hoặc làm thay đổi các phân hệ khác (HR, SYS, ESS, cấu hình dùng chung), AI BẮT BUỘC phải cảnh báo rõ ràng cho tôi trước khi thực hiện!

Yêu cầu hiện tại của tôi: [Mô tả tính năng bạn muốn AI hỗ trợ viết]
```

---

## 7. Phân Công Phụ Trách & Cơ Chế Cảnh Báo Tác Động Chéo (BẮT BUỘC CHO AI)

1. **Phân công module:** Lập trình viên **`huungociter`** chịu trách nhiệm chính về phân hệ **GA (Quản Trị Hành Chính)**, bao gồm cả 3 màn hình Đăng ký khách vào cổng (`VisitorRegistration`, `VisitorApproval`, `VisitorGate`).
2. **Quy tắc kiểm soát tác động chéo (Cross-Module Impact Protection):**
   - Mọi mã nguồn mới cho GA phải được cô lập hoàn toàn trong:
     - Database: Chỉ thao tác trên các bảng có tiền tố `GA_*` (`GA_MealOrders`, `GA_WorkCalendar`, `GA_Departments`, `GA_VisitorRegistrations`, `GA_VisitorDetails`).
     - Backend: Chỉ thao tác trong `HRM.Backend/Domains/GA/` và route `/api/ga/...`.
     - Frontend: Chỉ thao tác trong `HRM.Frontend/src/pages/GA/` (và `src/pages/ESS/VisitorRegistration/`).
3. **CẢNH BÁO BẮT BUỘC DÀNH CHO AI:**
   - Khi `huungociter` yêu cầu một tính năng hoặc chỉnh sửa mà **ảnh hưởng ra ngoài phạm vi GA**, bao gồm:
     - Sửa các bảng của domain khác: `HR_*`, `SYS_*`, `ESS_*` (đặc biệt cấm tự ý sửa/truncate `SYS_ProgramMenus`, `SYS_AuthorGroupMapping`).
     - Sửa code trong các thư mục domain khác: `Domains/HR/`, `Domains/SYS/`, `Domains/ESS/` hoặc `pages/HR/`, `pages/SYS/`, `pages/ESS/`.
     - Sửa các file dùng chung toàn hệ thống: `Program.cs`, middleware, authentication/JWT, shared layouts, base types, migration scripts dùng chung...
   - **Hành động bắt buộc của AI:**
     AI **KHÔNG ĐƯỢC TỰ Ý SỬA ÂM THẦM**, mà phải xuất cảnh báo nổi bật:
     > [!WARNING] **CẢNH BÁO TÁC ĐỘNG NGOÀI PHÂN HỆ GA (Gửi huungociter)**
     > - **Vấn đề phát hiện:** Yêu cầu này sẽ làm thay đổi file / bảng dữ liệu thuộc phân hệ khác: `[Danh sách file/bảng]`.
     > - **Rủi ro ảnh hưởng:** Có thể làm lỗi các tính năng đang hoạt động của phân hệ `[HR / SYS / ESS]`.
     > - **Giải pháp an toàn đề xuất:** [Cách xử lý chỉ cô lập trong module GA, hoặc cần xác nhận trước từ chủ quản dự án].
