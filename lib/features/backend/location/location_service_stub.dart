// Phần riêng cho Android/iOS/desktop của [GpsService] (xem location_service.dart).

/// Thiết bị có màn hình cài đặt vị trí / cài đặt ứng dụng để mở trực tiếp.
const bool platformCanOpenSettings = true;

/// Hướng dẫn bật GPS trên điện thoại.
const String platformEnableGpsHint =
    'Vuốt thanh thông báo xuống và bật "Vị trí" (GPS), hoặc bấm "Mở cài đặt vị trí" bên dưới.';

/// Hướng dẫn cấp lại quyền khi đã bị từ chối vĩnh viễn.
const String platformPermissionSettingsHint =
    'Mở Cài đặt → Ứng dụng → SmartMarket HRM → Quyền → Vị trí → chọn "Cho phép khi dùng ứng dụng".';
