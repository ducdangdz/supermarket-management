# Chạy đăng nhập Google

Backend và Flutter mặc định dùng chung OAuth Web Client ID đã có trong dự án.

1. Trong Google Cloud Console, mở OAuth client tương ứng và thêm Authorized JavaScript origins: `http://localhost:5000`. Nếu ứng dụng OAuth đang Testing, thêm email vào Test users. Việc này cần tài khoản chủ Google Cloud; sửa mã nguồn không thay được cấu hình này.
2. Khởi động backend như bình thường với DB_USERNAME/DB_PASSWORD đã cấu hình: `mvn spring-boot:run` trong thư mục backend. File .env.example chỉ là mẫu, Spring không tự đọc file .env.
3. Ở thư mục gốc Flutter chạy:

```powershell
flutter run -d chrome --web-hostname localhost --web-port 5000 --no-pub
```

4. Bấm nút Google tại màn đăng nhập. Email phải trùng nhân viên ACTIVE trong dbo.employees. Có thể đăng ký tài khoản nhân viên bằng email đó trước, hoặc nhờ quản trị viên tạo tài khoản. Quyền được lấy từ cơ sở dữ liệu.

Nếu dùng OAuth client của riêng bạn, đặt biến GOOGLE_CLIENT_ID cho backend và thêm `--dart-define=GOOGLE_CLIENT_ID=CLIENT_ID_CUA_BAN` vào lệnh Flutter. Hai giá trị phải giống nhau. Không cần client secret trong Flutter.

Lỗi origin_mismatch: kiểm tra địa chỉ JavaScript origin và cổng 5000. Lỗi access_denied: kiểm tra Test users và trạng thái ứng dụng OAuth. Lỗi chưa được cấp quyền: kiểm tra email và trạng thái nhân viên. Sau khi sửa cấu hình, khởi động lại backend và Flutter.

Chưa kiểm chứng đăng nhập bằng tài khoản Google thực tế hoặc cấu hình Google Cloud của chủ dự án.