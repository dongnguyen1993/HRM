# 📌 SỔ TAY NÂNG CẤP & TÍNH NĂNG TƯƠNG LAI (FEATURE BACKLOG) - HRM ENTERPRISE

Tài liệu này lưu trữ các giải pháp kiến trúc và tính năng được thống nhất đưa vào kế hoạch nâng cấp giai đoạn tiếp theo của hệ thống HRM Enterprise.

---

## 1. Nâng Cấp Phân Hệ Phiếu Lương: Server-Side PDF Engine (.NET 8 & QuestPDF)

### 1.1. Bối cảnh & Mục tiêu
- **Hiện tại (Đã hoàn thiện 100%):** Màn hình **Phiếu Lương Của Tôi** (`/ess/my-payslip`) hiển thị bảng lưới BaseTable, nhấp đúp mở Modal xem phiếu lương A5 ngang sắc nét bằng HTML/CSS và in ấn chuẩn xác qua Isolated Print Frame (đúng 1 tờ A5 duy nhất).
- **Mục tiêu tương lai:** Bổ sung engine sinh file `.pdf` trực tiếp từ máy chủ Backend (.NET 8) để cung cấp khả năng tải file lưu trữ và tự động hóa quy trình gửi email.

### 1.2. Giải pháp Kỹ thuật Đề xuất
- **Thư viện Backend:** `QuestPDF` (.NET 8 C#).
- **Lý do chọn:**
  - Hiệu năng vượt trội: Render 1 file PDF trong < 30ms, tốn cực ít RAM và CPU server.
  - Hỗ trợ thiết kế layout dạng Fluent API chuẩn A5 Landscape (210mm x 148mm).
  - Tự động nhúng font chữ chuẩn (*Times New Roman*), không phụ thuộc vào hệ điều hành của client hay máy in.
  - Hỗ trợ mã hóa bảo mật: Đặt mật khẩu mở file PDF (dùng 4 hoặc 6 số cuối CCCD / Ngày sinh của nhân viên) để bảo mật thông tin lương khi gửi qua email.

### 1.3. Các tính năng triển khai sau này
1. **Nút "Tải Phiếu Lương PDF" (`Download PDF`):**
   - Đặt trên header của Modal xem phiếu lương cạnh nút In.
   - Gọi API: `GET /api/ess/my-payslip/download-pdf?periodId=2026-08`.
   - Trả về file nhị phân `application/pdf` để nhân viên tải về lưu trữ offline trên máy tính hoặc điện thoại.
2. **Tự Động Gửi Email Phiếu Lương Hàng Tháng (Batch Email Service):**
   - Khi phòng Nhân sự (HR) duyệt và bấm **"Công bố bảng lương"**, hệ thống chạy background worker (Hangfire / BackgroundService) tự động sinh file PDF cho từng công nhân và gửi vào email cá nhân có kèm mật khẩu bảo vệ.
3. **Xuất PDF Hàng Loạt Cho Phòng HR (HR Bulk Export):**
   - Trên màn hình **Quản Lý Bảng Lương Nhà Máy** (`/hr/payroll`), bổ sung tính năng xuất file `.zip` chứa toàn bộ các file PDF phiếu lương của từng nhân viên theo phòng ban để phục vụ kiểm toán hoặc in ấn hàng loạt.
4. **Tích hợp Ký Số Điện Tử (Digital Signature):**
   - Tự động ký số bằng chữ ký số doanh nghiệp (PKI / HSM) lên file PDF trước khi phát hành để có giá trị pháp lý tương đương phiếu lương giấy có đóng dấu mộc đỏ.

---

*Cập nhật lần cuối: 23/11/2026 - Ghi nhận theo yêu cầu người dùng.*
