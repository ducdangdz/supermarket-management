# SmartMarket HRM API

Spring Boot backend cho Flutter app `supermarket_hrm`; kết nối SQL Server database `smartmarket_hrm`.

## Cấu hình và chạy

Mở PowerShell trong thư mục `backend`, rồi đặt mật khẩu SQL Server cho phiên làm việc hiện tại. Không đưa mật khẩu vào Git:

```powershell
$env:DB_USERNAME = "sa"
$env:DB_PASSWORD = "MAT_KHAU_SQL_SERVER_CUA_BAN"
$env:DB_HOST = "localhost"
$env:DB_PORT = "1433"
$env:DB_NAME = "smartmarket_hrm"
$env:GOOGLE_CLIENT_ID = "GOOGLE_WEB_CLIENT_ID_CUA_NHOM"
mvn spring-boot:run
```

Kiểm tra kết nối tại `http://localhost:8080/api/health`. Kết quả đúng là:

```json
{"status":"UP","database":"CONNECTED"}
```

## API hiện có

| Method | URL | Mục đích |
| --- | --- | --- |
| GET | `/api/health` | Kiểm tra API và SQL Server |
| GET | `/api/employees` | Danh sách nhân viên; hỗ trợ `?branchId=1` |
| GET | `/api/employees/{id}` | Lấy profile nhân viên |
| GET | `/api/employees/{id}/schedules?from=2026-10-01&to=2026-10-31` | Lấy lịch làm và trạng thái chấm công |

## Flutter gọi API

- Android Emulator: `http://10.0.2.2:8080/api`
- Windows/Web cùng máy: `http://localhost:8080/api`
- Điện thoại thật: dùng IP LAN của máy chạy backend, ví dụ `http://192.168.1.10:8080/api`

Flutter chỉ gọi API; không được kết nối trực tiếp tới SQL Server.

## Đăng nhập Google và phân quyền

Flutter đăng nhập với Google, nhận **Google ID token**, rồi gọi:

```http
POST /api/auth/google
Content-Type: application/json

{"idToken":"GOOGLE_ID_TOKEN"}
```

Backend xác minh chữ ký, issuer, audience (`GOOGLE_CLIENT_ID`) và email đã xác minh. Email Google phải trùng với email của một nhân viên `ACTIVE` trong bảng `dbo.employees`.

Với mọi API trừ `/api/health` và `/api/auth/google`, Flutter gửi header:

```http
Authorization: Bearer GOOGLE_ID_TOKEN
```

Quyền được kiểm soát từ bảng `roles`:

- `ADMIN`, `MANAGER`, `HR`: quản lý nhân viên, ca và lịch.
- `ADMIN`, `MANAGER`: tạo QR chấm công.
- `EMPLOYEE`: chỉ xem profile, lịch và lịch sử/chấm công của chính mình.
