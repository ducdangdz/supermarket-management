# Tài khoản, đăng ký và khôi phục mật khẩu

## Các bước bật chức năng trên máy của bạn

1. Nếu chưa có database, chạy schema `database/smartmarket_hrm_sql_server.sql` trước.
2. Trong SQL Server Management Studio, chạy `backend/database/migrations/001_account_auth.sql`. Script giữ các hồ sơ cũ và bổ sung bảng mã xác nhận/phiên đăng nhập. Index Google được chuyển thành unique index chỉ áp dụng cho giá trị khác NULL để nhiều tài khoản email có thể cùng tồn tại.
3. Cấu hình SQL Server như `backend/README.md`, rồi cấu hình SMTP qua biến môi trường của phiên terminal chạy backend:

```powershell
$env:MAIL_HOST = "smtp.example.com"
$env:MAIL_PORT = "587"
$env:MAIL_USERNAME = "tai_khoan_smtp_cua_ban"
$env:MAIL_PASSWORD = "mat_khau_ung_dung_hoac_smtp"
$env:MAIL_FROM = "dia_chi_gui_da_duoc_xac_minh"
$env:MAIL_AUTH = "true"
$env:MAIL_STARTTLS = "true"
```

Thay các giá trị ví dụ bằng cấu hình nhà cung cấp email. Không ghi mật khẩu thật vào Git hoặc gửi vào chat. `.env.example` chỉ là danh sách mẫu; Spring Boot không tự đọc file `.env` này.

4. Khởi động lại backend để nạp API mới:

```powershell
cd backend
mvn spring-boot:run
```

5. Chạy Flutter tại thư mục gốc:

```powershell
flutter run -d chrome --no-pub
```

Nếu đang chạy Flutter, nhấn R để khởi động lại. Nếu đang chạy backend cũ, dừng từ terminal của chính bạn và chạy lại sau khi migration đã hoàn tất.

## Cách sử dụng

- **Đăng nhập**: email hoặc mã nhân viên và mật khẩu đã tạo. Luồng này gọi API thật, không đăng nhập bằng tài khoản mẫu.
- **Đăng ký ngay**: họ tên, email, mật khẩu và xác nhận. Mã 6 số được gửi qua email; xác nhận đúng mới tạo tài khoản và đăng nhập.
- Tài khoản mới luôn là **EMPLOYEE**, chưa có chi nhánh. Quản lý/nhân sự cần cập nhật chi nhánh và phân ca trước khi người dùng có lịch làm.
- **Quên mật khẩu**: nhập email, nhận mã và đặt mật khẩu mới. Sau khi đổi, đăng nhập lại; các phiên đăng nhập bằng mật khẩu trước đó bị thu hồi.
- Hồ sơ Google đã có sẵn có thể dùng Quên mật khẩu để thiết lập mật khẩu sau khi xác nhận quyền sở hữu email. Google vẫn được hỗ trợ.

Mật khẩu mới tối thiểu 8 ký tự, tối đa 72 byte UTF-8. Mã dùng một lần trong 10 phút, giới hạn 5 lần nhập sai; tối đa 3 yêu cầu gửi mã trong 15 phút cho một email. Đăng nhập sai 5 lần bị giới hạn 15 phút theo định danh trên một tiến trình backend. Phiên đăng nhập mật khẩu hết hạn sau 8 giờ.

Mật khẩu và mã email được băm bằng BCrypt. Database chỉ giữ SHA-256 của token phiên, không giữ token thô. API đăng ký không nhận quyền quản trị từ phía ứng dụng.

## API

| Endpoint | Nội dung |
| --- | --- |
| POST /api/auth/login | username, password → token, user |
| POST /api/auth/register | fullName, email, password → challengeId |
| POST /api/auth/verify-registration | challengeId, code → token, user |
| POST /api/auth/forgot-password | email → challengeId, phản hồi chung |
| POST /api/auth/reset-password | challengeId, code, password |
| POST /api/auth/logout | Authorization: Bearer token |
| GET /api/auth/me | Thông tin người dùng trong phiên |

Các API dữ liệu nhận cả phiên mật khẩu và Google ID token. Email không tồn tại vẫn nhận phản hồi chung khi yêu cầu quên mật khẩu. Mã xác nhận không được trả về trong API.

## Giới hạn xác minh

Các kiểm thử dùng email và database giả lập, không gửi email thật và không thay đổi SQL Server của bạn. Cần hoàn tất cấu hình phía trên để kiểm chứng toàn bộ luồng với tài khoản thật. Chức năng gửi mã trả lỗi cấu hình rõ ràng khi chưa có SMTP.

## Xác nhận bản cập nhật

- 31 kiểm thử Flutter đạt, gồm giao diện nhỏ, đăng ký/xác nhận email, đăng nhập và đặt lại mật khẩu qua HTTP giả lập.
- 20 kiểm thử backend đạt qua JUnit, gồm băm mật khẩu/mã, giới hạn thử sai, thu hồi phiên và chặn quyền quản lý đối với tài khoản mới.
- Build Flutter web thành công.
- Chưa áp dụng migration lên SQL Server của bạn và chưa gửi email thật. Các bước SQL/SMTP ở trên là bắt buộc trước khi dùng tài khoản thật.
