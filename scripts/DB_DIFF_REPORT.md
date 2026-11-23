# Bao Cao So Sanh Co So Du Lieu: Live HRM_TEST_DB (DB_Real) vs Snapshot Chuan Hoa
Thoi gian thuc hien: 2026-11-23 10:18:27
Thoi gian snapshot chuan: 2026-11-23 10:18:23

## 1. Danh Gia Trang Thai Cot Quyen Chuan CRUD (SYS_AuthorGroupMapping)
| Tieu chi | Trang thai Live DB | Danh gia | Ghi chu |
|:---|:---:|:---:|:---|
| Cot IsUpdate (Quyen cap nhat chuan) | CO TON TAI (YES) | OK | Backend & Frontend yeu cau |
| Cot cu IsSave | DA XOA (CLEAN) | OK | Bi loai bo theo chuan CRUD |
| Cot cu IsEdit | KHONG CO (CLEAN) | OK | Khong su dung |

## 2. Bang Du Lieu (Tables Diff)
- **Tong so bang Live DB:** 40
- **Tong so bang Snapshot:** 40

- Khong co bang moi phat sinh.
- Khong co bang nao bi thieu so voi Snapshot.

## 3. Cot Du Lieu (Columns Diff)
- Khong co cot moi phat sinh.
- Khong co cot nao bi thieu so voi Snapshot.

## 4. Stored Procedures & Functions Diff
- Danh sach Stored Procedures dong nhat 100%.

## 5. Danh Muc Menu Chuong Trinh (SYS_ProgramMenus Diff)
- **Tong so menu Live DB:** 35
- **Tong so menu Snapshot:** 35
- Danh muc 37 Menu dong nhat 100%.

## 6. So Sanh So Luong Dong Du Lieu (Row Count)
| Ten Bang | Dong trong Live DB | Dong trong Snapshot | Chenh lech |
|:---|:---:|:---:|:---:|
| __DbMigrationHistory | 6 | 6 | 0 (Dong nhat) |
| GA_DepartmentMealOrders | 550 | 550 | 0 (Dong nhat) |
| GA_Departments | 22 | 22 | 0 (Dong nhat) |
| GA_VisitorDetails | 144 | 144 | 0 (Dong nhat) |
| GA_VisitorGateLogs | 2 | 2 | 0 (Dong nhat) |
| GA_VisitorItems | 0 | 0 | 0 (Dong nhat) |
| GA_VisitorRegistrations | 3 | 3 | 0 (Dong nhat) |
| GA_WorkCalendar | 9 | 9 | 0 (Dong nhat) |
| HR_Departments | 51 | 51 | 0 (Dong nhat) |
| HR_Employees | 1046 | 1046 | 0 (Dong nhat) |
| HR_LaborContracts | 3 | 3 | 0 (Dong nhat) |
| HR_LeaveTypes | 4 | 4 | 0 (Dong nhat) |
| HR_MachineRecords | 2724938 | 2724938 | 0 (Dong nhat) |
| HR_OtRegistrations | 3 | 3 | 0 (Dong nhat) |
| HR_PayrollEmployeeMonthly | 24 | 24 | 0 (Dong nhat) |
| HR_PayrollPeriod | 3 | 3 | 0 (Dong nhat) |
| HR_PayrollSalaryItem | 564 | 564 | 0 (Dong nhat) |
| HR_Positions | 0 | 0 | 0 (Dong nhat) |
| HR_PositionsGrade | 26 | 26 | 0 (Dong nhat) |
| HR_PositionsRole | 14 | 14 | 0 (Dong nhat) |
| HR_WorkRequests | 6 | 6 | 0 (Dong nhat) |
| HR_WorkShifts | 2 | 2 | 0 (Dong nhat) |
| HR_WorkSummary | 445816 | 445816 | 0 (Dong nhat) |
| SYS_Announcements | 3 | 3 | 0 (Dong nhat) |
| SYS_AuditLogs | 9344 | 9344 | 0 (Dong nhat) |
| SYS_AuthorGroupMapping | 231 | 231 | 0 (Dong nhat) |
| SYS_AuthorGroups | 16 | 16 | 0 (Dong nhat) |
| SYS_CommonCodes | 8 | 8 | 0 (Dong nhat) |
| SYS_DeviceSetup | 20 | 20 | 0 (Dong nhat) |
| SYS_NotificationEvents | 7 | 7 | 0 (Dong nhat) |
| SYS_NotificationMatrix | 0 | 0 | 0 (Dong nhat) |
| SYS_Notifications | 0 | 0 | 0 (Dong nhat) |
| SYS_ProgramMenus | 35 | 35 | 0 (Dong nhat) |
| SYS_SystemSettings | 1 | 1 | 0 (Dong nhat) |
| SYS_UserAttachments | 12 | 12 | 0 (Dong nhat) |
| SYS_UserGroupMapping | 69 | 69 | 0 (Dong nhat) |
| SYS_Users | 33 | 33 | 0 (Dong nhat) |
| SYS_UserThemeSettings | 29 | 29 | 0 (Dong nhat) |
| SYS_UserTokens | 1104 | 1104 | 0 (Dong nhat) |
| sysdiagrams | 0 | 0 | 0 (Dong nhat) |
