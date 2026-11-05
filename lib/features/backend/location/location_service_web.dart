// Phần riêng cho trình duyệt của [GpsService] (xem location_service.dart).
// Trên web, geolocator dùng navigator.geolocation; trình duyệt không cho mở
// cài đặt hệ thống nên chỉ hiển thị hướng dẫn.

/// Trình duyệt không mở được màn hình cài đặt vị trí của hệ điều hành.
const bool platformCanOpenSettings = false;

/// Hướng dẫn bật dịch vụ vị trí khi chạy trên trình duyệt.
const String platformEnableGpsHint =
    'Hãy bật dịch vụ vị trí của máy tính/điện thoại (Windows: Cài đặt → Quyền riêng tư → Vị trí) rồi bấm "Thử lại".';

/// Hướng dẫn cấp lại quyền khi trình duyệt đã chặn vị trí.
const String platformPermissionSettingsHint =
    'Bấm biểu tượng ổ khóa cạnh thanh địa chỉ → Vị trí → "Cho phép", rồi tải lại trang và bấm "Thử lại".';
