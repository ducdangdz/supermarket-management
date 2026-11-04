# Giao diện team kết nối backend

Đã đổi luồng chính: đăng nhập tài khoản database → trang Không gian làm việc của team → phân hệ theo vai trò thật.

- EMPLOYEE: mở bộ màn nhân viên của team (tổng quan, lịch làm, lịch sử, hồ sơ, QR).
- ADMIN/MANAGER/HR: có thêm quản lý vận hành và báo cáo của team.
- Không đổi vai trò trải nghiệm trong phiên đăng nhập thật.
- Dữ liệu quản lý và báo cáo lấy từ API /api/management/team-data, không thay bằng mẫu khi backend lỗi.
- Thêm nhân viên, đổi trạng thái, tạo ca, bật/tắt ca, phân lịch và phê duyệt gọi API và đợi xác nhận trước khi báo thành công.
- Quét/nhập QR và vị trí gọi API chấm công; không ghi chấm công giả vào MockData.
- Báo cáo xuất CSV thật trên trình duyệt, theo khoảng ngày và nhân viên. Xuất PDF/XLSX chưa triển khai thật nên PDF bị khóa trong phiên thật.
- Màn selfie giả trước đây đã bỏ khỏi chấm công thật; chưa bổ sung tải ảnh bằng chứng lên máy chủ. Ảnh bằng chứng đã có trong database vẫn hiển thị trong quản lý/báo cáo.
- Các màn và lớp mẫu được giữ để tham khảo/kiểm thử; luồng đăng nhập chính không dùng nguồn mẫu đó.

## Chạy lại

Dừng backend và Flutter cũ bằng Ctrl+C. Giữ nguyên biến kết nối SQL Server đã cấu hình trong terminal backend.

Terminal backend:

```powershell
cd "C:\Users\admin\Downloads\flutter_windows_3.44.9-stable\supermarket_hrm\backend"
$env:SERVER_PORT="8081"
mvn spring-boot:run
```

Terminal Flutter:

```powershell
cd "C:\Users\admin\Downloads\flutter_windows_3.44.9-stable\supermarket_hrm"
flutter run -d chrome --web-hostname localhost --web-port 5000 --dart-define=API_BASE_URL=http://localhost:8081/api --no-pub
```

Cần khởi động lại backend vì đã thêm API mới. Không cần tạo database lại hoặc chạy migration mới cho thay đổi này; các migration đăng nhập trước đó vẫn phải có.

Nếu quản lý chưa được gán chi nhánh, tạo nhân viên/ca mới sẽ báo rõ thay vì tự chọn chi nhánh bất kỳ. Quản trị viên cần gán chi nhánh phù hợp trong database; vai trò ADMIN có thể làm việc với chi nhánh đầu tiên đang hiển thị.

## Kiểm tra

37 kiểm thử Flutter và 25 kiểm thử backend đều đạt; dựng web thành công. Kiểm thử sử dụng API/SQL giả lập để xác minh điều hướng, vai trò, quyền truy cập, lỗi dữ liệu và không thay bằng dữ liệu mẫu. Chưa kiểm chứng toàn bộ thao tác ghi trên SQL Server đang chạy của người dùng sau khi khởi động lại backend.

Chưa tạo commit hoặc hoàn tất trạng thái merge Git trong lượt này.