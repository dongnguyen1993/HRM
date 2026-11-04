# HRM Enterprise Project Rules

## 1. Quy định Git & Đồng bộ GitHub (BẮT BUỘC)
- **TUYỆT ĐỐI KHÔNG tự ý chạy lệnh `git push` hay đồng bộ mã nguồn lên GitHub** sau khi sửa code hoặc hoàn thành tính năng.
- **CHỈ thực hiện commit và push lên GitHub khi người dùng có yêu cầu cụ thể, rõ ràng** (ví dụ: *"hãy push code lên github"*, *"push git nhánh main"*, v.v.).
- Khi hoàn thành các thay đổi, chỉ báo cáo kết quả thực hiện, danh sách các file đã sửa đổi ở localhost và các bước kiểm tra cần thiết.

## 2. Quy định Bắt Buộc về Tiếng Việt & Mã hóa Ký tự (UTF-8 Encoding)
- **Hiện tượng vỡ font (Mojibake):** Khi chạy PowerShell trên Windows, lệnh `Get-Content` mặc định đọc file theo bảng mã ANSI (Windows-1252). Khi đẩy nội dung vào CSDL hoặc ghi đè file, chuỗi tiếng Việt Unicode có dấu (ví dụ: `Cổng Tự Phục Vụ`, `Quản Trị Nhân Sự`) sẽ bị vỡ thành các ký tự lạ như `Cá»•ng Tá»± Phá»¥c Vá»¥`.
- **Quy tắc thực thi bắt buộc:**
  1. Mọi script PowerShell đọc file `.sql`, `.json`, `.ts` hoặc kết nối CSDL phải luôn khai báo bảng mã UTF-8:
     ```powershell
     [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
     $OutputEncoding = [System.Text.Encoding]::UTF8
     ```
  2. Đọc file qua `Get-Content -Encoding UTF8` hoặc dùng thư viện .NET: `[System.IO.File]::ReadAllText($path, [System.Text.Encoding]::UTF8)`.
  3. Mọi câu lệnh SQL chứa ký tự tiếng Việt Unicode trong CSDL phải luôn có tiền tố `N'...'` (ví dụ: `N'Cổng Tự Phục Vụ (ESS)'`).
  4. Luôn sử dụng script thực thi SQL chuẩn đã tích hợp sẵn UTF-8: `d:\HRM\scripts\execute_sql.ps1`.
  5. Khi cần khôi phục lại toàn bộ font menu tiếng Việt chuẩn: Chạy file script `d:\HRM\scripts\Fix_Vietnamese_Menu_Encoding.sql`.


