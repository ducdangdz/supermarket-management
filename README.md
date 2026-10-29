# SmartMarket HRM

Một dự án Flutter tại thư mục gốc, dùng chung `pubspec.yaml`, `lib/main.dart`, thư viện và cấu hình nền tảng. Backend Spring Boot và SQL giữ trong `backend/` và `database/`.

## Chạy ứng dụng

Mở terminal ở thư mục chứa README này:

```powershell
flutter pub get
flutter run -d chrome
```

Không chuyển vào thư mục con. VS Code có cấu hình **SmartMarket HRM** trỏ đến `lib/main.dart` ở gốc.

Trang đầu gồm:

- **Kết nối hệ thống**: luồng Google, nhân viên/quản lý, phân ca và QR kết nối backend của bản gốc.
- **Ứng dụng nhân viên**: đăng nhập bằng tài khoản đã tạo, đăng ký và quên mật khẩu qua email.
- Các màn hình quản lý và báo cáo: dữ liệu mẫu và lựa chọn vai trò phục vụ trình diễn được giữ nguyên.

Các nguồn dữ liệu vẫn theo thiết kế hiện có, chưa đồng bộ dữ liệu mẫu với SQL Server. Lựa chọn vai trò demo không thay thế phân quyền backend. Hai lối vào tài khoản đều sử dụng API thật và không thay thế đăng nhập sai bằng danh tính mẫu.

## Backend

Xem `backend/README.md` để cấu hình SQL Server, Google Client ID và khởi chạy Spring Boot. Backend mặc định dùng cổng **8080**. Luồng kết nối hệ thống dùng `localhost:8080/api` trên web và `10.0.2.2:8080/api` trên Android Emulator.

Có thể đổi endpoint cho luồng kết nối hệ thống:

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:8080/api
```

Khi dùng điện thoại thật, thay localhost bằng IP LAN máy chạy backend. Các luồng đăng nhập tài khoản dùng chung API_BASE_URL và backend hiện có. Một số màn hình quản lý/báo cáo vẫn dùng dữ liệu mẫu như đã ghi ở trên.

## Cấu trúc

```text
lib/
  main.dart             # Điểm khởi động duy nhất
  app.dart              # Module nhân viên với router
  core/                 # API, cấu hình, lưu trữ và theme
  features/
    backend/            # Luồng Google/API, QR và vị trí của bản gốc
    launcher/           # Cổng vào các chức năng
    auth/
    dashboard/
    schedules/
    attendance_history/
    qr_checkin/
    profile/
    management/
    reports/
  models/
  navigation/
  services/
test/                   # Kiểm thử chung
backend/                # Spring Boot
database/              # SQL
android/ ios/ web/       # Cấu hình Flutter chung
windows/ linux/ macos/
```

## Kiểm tra

```powershell
flutter test
dart analyze lib test
flutter build web
```

Bản hợp nhất dùng `google_sign_in` 7 cho cả hai luồng; module nhân viên đã điều chỉnh lời gọi SDK tương ứng. Font hệ thống của Flutter giúp khởi động không cần tải Google Fonts.

Đã chạy đạt 13 kiểm thử và build web. Chưa xác minh Google với tài khoản thật, SQL Server, camera/QR trên thiết bị hay build Android/iOS. GPS native chưa được triển khai trong luồng backend gốc. Mã còn các thông báo lint/API cũ được giữ từ hai bản ban đầu.

## Giao diện dùng chung

Các module sử dụng cùng theme tại `lib/core/theme/app_theme.dart` và bảng màu `app_colors.dart`.
Các thành phần dùng lại nằm trong `lib/core/widgets/`:

- `AppBrand`: nhận diện SmartMarket.
- `AppAuthLayout`: khung đăng nhập cho tài khoản nhân viên và Google.
- `AppWorkspace`: thanh bên trên máy tính, thanh dưới/menu Thêm trên điện thoại.
- `AppStatCard` / `AppStatGrid`: thẻ thống kê có kích thước thích ứng.
- `AppAvatar`: ảnh đại diện có hiển thị thay thế khi mất mạng.

Khi thêm màn hình, sử dụng theme chung thay vì tạo ThemeData riêng. Giữ màu đỏ/cam/xanh theo ý nghĩa trạng thái. Các báo cáo có tùy chọn `embedded` để dùng trong trung tâm báo cáo mà không lặp thanh tiêu đề.

Kiểm tra thay đổi giao diện bằng `flutter test test/ui_layout_test.dart`. Bộ kiểm thử bao gồm trang chủ ở 320/1440 px, các mục quản lý trên điện thoại, menu phê duyệt, năm tab báo cáo và form đăng nhập ở màn hình nhỏ.


## Đăng nhập, đăng ký, quên mật khẩu

Xem [hướng dẫn tài khoản](backend/ACCOUNT_AUTH.md) để chạy migration SQL và cấu hình SMTP. Người mới đăng ký với quyền Nhân viên sau khi xác minh email. Cả hai lối vào tài khoản dùng cùng màn hình và API.


