# BÁO CÁO ĐỐI SOÁT CHI TIẾT: DB REAL (MỚI ĐỒNG BỘ) VS DB TEST CHUẨN HÓA
- **Thời gian phân tích:** 2026-11-23 18:43:27
- **Server:** 172.26.75.23,1433 | Database: HRM_TEST_DB

---

## 1. ĐÁNH GIÁ CÁC ĐIỂM CỐT TỬ ẢNH HƯỞNG ĐẾN CODE DEPLOYMENT

| Hạng mục kiểm tra | Trạng thái trên DB Real hiện tại | Chuẩn Code Backend/Frontend | Mức độ nghiêm trọng | Hành động cần thiết |
| :--- | :---: | :---: | :---: | :--- |
| **Cột [IsUpdate] trong SYS_AuthorGroupMapping** | ✅ ĐÃ CÓ | Bắt buộc có | **NGHIÊM TRỌNG (500)** | Đã chuẩn hóa. |
| **Cột cũ [IsSave] trong SYS_AuthorGroupMapping** | ✅ ĐÃ XÓA SẠCH | Bắt buộc xóa | **CẢNH BÁO** | Đã sạch. |
| **Bảng [HR_Employees] (Hồ sơ Nhân viên)** | ✅ ĐÃ TỒN TẠI (1045 dòng) | Bắt buộc có | **NGHIÊM TRỌNG (500)** | Đã chuẩn. |
| **View [dbo.VW_HR_Employees]** | ✅ ĐÃ CÓ | Bắt buộc có | **NGHIÊM TRỌNG (500)** | Đã chuẩn. |
| **29 cột nhân sự cũ trong [SYS_Users]** | ✅ ĐÃ DỌN SẠCH | Tách sang HR_Employees | **CẢNH BÁO KIẾN TRÚC** | Đã chuẩn 16 cột tài khoản. |
| **Số lượng Menu chương trình (SYS_ProgramMenus)** | **37 Menus** | **37 Menus** | **TRUNG BÌNH (404/403)** | Đã đủ 37 menu. |

---

## 2. BẢNG DỮ LIỆU (TABLES DIFF)
- **Tổng số bảng trên DB Real:** 40
- **Tổng số bảng trên DB Test Chuẩn:** 40

### ✅ Không có bảng nào bị thiếu so với DB Test Chuẩn.

### ✅ Không có bảng thừa.

---

## 3. MENU CHƯƠNG TRÌNH THIẾU (SYS_ProgramMenus DIFF)
✅ Toàn bộ 37 Menu chương trình đồng nhất 100% giữa 2 DB.

---

## 4. ĐỐI SOÁT SỐ LƯỢNG BẢN GHI (ROW COUNT DIFF)
| Tên Bảng | DB Real (Vừa đồng bộ) | DB Test Chuẩn | Chênh lệch (Real - Test) |
| :--- | :---: | :---: | :---: |
| __DbMigrationHistory | 6 | 6 | 0 (Đồng nhất) |
| GA_DepartmentMealOrders | 556 | 550 | +6 |
| GA_Departments | 22 | 22 | 0 (Đồng nhất) |
| GA_VisitorDetails | 144 | 144 | 0 (Đồng nhất) |
| GA_VisitorGateLogs | 2 | 2 | 0 (Đồng nhất) |
| GA_VisitorItems | 0 | 0 | 0 (Đồng nhất) |
| GA_VisitorRegistrations | 3 | 3 | 0 (Đồng nhất) |
| GA_WorkCalendar | 9 | 9 | 0 (Đồng nhất) |
| HR_Departments | 51 | 51 | 0 (Đồng nhất) |
| HR_Employees | 1045 | 1047 | -2 |
| HR_LaborContracts | 3 | 3 | 0 (Đồng nhất) |
| HR_LeaveTypes | 4 | 4 | 0 (Đồng nhất) |
| HR_MachineRecords | 2724937 | 2724938 | -1 |
| HR_OtRegistrations | 3 | 3 | 0 (Đồng nhất) |
| HR_PayrollEmployeeMonthly | 24 | 20 | +4 |
| HR_PayrollPeriod | 3 | 2 | +1 |
| HR_PayrollSalaryItem | 564 | 340 | +224 |
| HR_Positions | 0 | 0 | 0 (Đồng nhất) |
| HR_PositionsGrade | 26 | 26 | 0 (Đồng nhất) |
| HR_PositionsRole | 14 | 14 | 0 (Đồng nhất) |
| HR_WorkRequests | 6 | 6 | 0 (Đồng nhất) |
| HR_WorkShifts | 2 | 2 | 0 (Đồng nhất) |
| HR_WorkSummary | 445816 | 445816 | 0 (Đồng nhất) |
| SYS_Announcements | 3 | 3 | 0 (Đồng nhất) |
| SYS_AuditLogs | 9376 | 9483 | -107 |
| SYS_AuthorGroupMapping | 233 | 233 | 0 (Đồng nhất) |
| SYS_AuthorGroups | 16 | 16 | 0 (Đồng nhất) |
| SYS_CommonCodes | 8 | 8 | 0 (Đồng nhất) |
| SYS_DeviceSetup | 20 | 20 | 0 (Đồng nhất) |
| SYS_NotificationEvents | 7 | 7 | 0 (Đồng nhất) |
| SYS_NotificationMatrix | 0 | 0 | 0 (Đồng nhất) |
| SYS_Notifications | 0 | 0 | 0 (Đồng nhất) |
| SYS_ProgramMenus | 37 | 37 | 0 (Đồng nhất) |
| SYS_SystemSettings | 1 | 1 | 0 (Đồng nhất) |
| SYS_UserAttachments | 12 | 12 | 0 (Đồng nhất) |
| SYS_UserGroupMapping | 69 | 69 | 0 (Đồng nhất) |
| SYS_Users | 33 | 34 | -1 |
| SYS_UserThemeSettings | 29 | 29 | 0 (Đồng nhất) |
| SYS_UserTokens | 1113 | 1136 | -23 |
| sysdiagrams | 0 | 0 | 0 (Đồng nhất) |


