# Hoàn thiện giao diện và luồng nghiệp vụ

## Thay đổi đã áp dụng

- Trang tổng quan mới: lời chào và thông tin tài khoản, quyền hiện tại, số liệu từ database, tìm chức năng, công việc chờ xử lý, thông tin chi nhánh và thời điểm tải dữ liệu.
- Bố cục thích ứng trên điện thoại 320/390 px và máy tính 1440 px. Các màn nghiệp vụ của team vẫn được truy cập từ trang này.
- Làm mới dữ liệu không làm trắng toàn bộ trang. Khi lỗi, thông báo rõ ràng và giữ nội dung đang xem. Lỗi tải lần đầu có màn thử lại và đăng xuất.
- Biểu mẫu thêm/sửa nhân viên: kiểm tra mã, email, điện thoại, chọn quyền và chi nhánh, khóa nút trong khi lưu, hiển thị lỗi ngay trong biểu mẫu.
- Xác nhận trước khi khóa/kích hoạt tài khoản và đăng xuất. Không cho khóa hoặc đổi quyền chính tài khoản đang đăng nhập từ màn quản lý nhân viên.
- Admin có thể chỉnh sửa tài khoản Manager để gán chi nhánh. Manager/HR chưa có chi nhánh sẽ không nhìn thấy dữ liệu của chi nhánh khác.
- Manager/HR chỉ được quản lý tài khoản EMPLOYEE cùng chi nhánh; không thể cấp quyền ADMIN/MANAGER/HR bằng yêu cầu API tự tạo. Admin quản lý các tài khoản khác trong hệ thống.
- Dữ liệu quản lý, danh sách nhân viên, lịch, ca, khu vực, hồ sơ và lịch sử được kiểm tra phạm vi chi nhánh trên server. Nhân viên chỉ xem hồ sơ/lịch sử cá nhân.
- Check-in/check-out chỉ cho chính tài khoản đang đăng nhập. Tạo QR bị giới hạn theo quyền và chi nhánh của ca làm.
- Dữ liệu trùng/ràng buộc trả lỗi 409 có thông báo, thay cho thông báo lỗi máy chủ chung. Lỗi mạng, timeout, phiên hết hạn có thông báo riêng.
- Xuất CSV có xử lý giá trị bắt đầu bằng ký tự công thức để tránh nội dung tên/mã bị bảng tính diễn giải như công thức.
- Sửa trạng thái nhân viên đã ra ca và bỏ dòng thông báo đã lưu ảnh khi hệ thống chưa có tải ảnh thật.

## Chạy phiên bản mới

Dừng backend cũ bằng Ctrl+C và chạy lại trong terminal đã cấu hình tài khoản SQL Server:

```powershell
cd "C:\Users\admin\Downloads\flutter_windows_3.44.9-stable\supermarket_hrm\backend"
mvn spring-boot:run
```

Dừng Flutter cũ và chạy lại:

```powershell
cd "C:\Users\admin\Downloads\flutter_windows_3.44.9-stable\supermarket_hrm"
flutter run -d chrome --web-hostname localhost --web-port 5000 --dart-define=API_BASE_URL=http://localhost:8081/api --no-pub
```

Không cần tạo lại database hoặc tài khoản. Nếu Manager chưa có chi nhánh: đăng nhập Admin → Quản lý vận hành → Nhân viên → Sửa thông tin → chọn chi nhánh → Lưu.

## Kiểm tra và giới hạn

43 kiểm thử Flutter và 35 kiểm thử backend đạt. Đã kiểm tra bố cục trên nhiều kích thước và chụp ảnh dựng từ giao diện thật. Ảnh xem trước sử dụng dữ liệu kiểm thử.

Các kiểm thử phân quyền sử dụng SQL giả lập; cần khởi động lại backend để các thay đổi có hiệu lực trên máy người dùng. Chưa thực hiện kiểm toán bảo mật toàn diện hoặc kiểm thử xâm nhập triển khai thực tế.

Các phần chưa hoàn thiện từ trước: tải ảnh selfie lên server, xuất PDF/XLSX thật. Đăng ký và khôi phục mật khẩu cần cấu hình SMTP hoạt động. Luồng đang dùng database thật không tự thay dữ liệu mẫu khi API lỗi.

Không tự chỉnh dữ liệu tài khoản hoặc gán chi nhánh trong database trong lượt này. Chưa tạo commit hoặc hoàn tất trạng thái merge Git.