# API chấm công QR + GPS + ảnh bằng chứng

Mọi API cần header `Authorization: Bearer <Google ID token>`.

## 1. Tạo QR (Quản lý)

`POST /api/management/qr-sessions`

```json
{
  "shiftId": 1,
  "workAreaId": 1,
  "sessionType": "CHECK_IN",
  "expiresInSeconds": 60
}
```

Kết quả trả về `token`. Đưa token này vào QR; backend chỉ lưu SHA-256 của token.

## 2. Lịch làm hôm nay của tôi

`GET /api/attendance/me/today`: danh sách ca hôm nay kèm `requireQr`, `requireLocation`,
`requireEvidence`, `attendanceStatus`, `checkInAt`, `checkOutAt`.

## 3. Upload ảnh bằng chứng

`POST /api/attendance/evidence` (multipart, field `file`, JPEG/PNG ≤ 5MB)

```json
{ "fileUrl": "/uploads/evidence/<hash>.jpg", "fileHash": "<sha256>", "sizeBytes": 123456 }
```

Ảnh xem được tại `http://<backend>/uploads/evidence/<hash>.jpg`.

## 4. Check-in / Check-out

`POST /api/attendance/check-in` và `POST /api/attendance/check-out`, cùng body:

```json
{
  "qrToken": "TOKEN_TRONG_QR",
  "latitude": 10.7769,
  "longitude": 106.7009,
  "accuracyMeters": 15,
  "clientTime": "2026-10-21T07:55:00.000+07:00",
  "deviceInfo": "Android 14 · Samsung SM-A515F",
  "evidence": { "fileHash": "<sha256 từ bước 3>", "capturedAt": "2026-10-21T07:54:50.000+07:00" }
}
```

`scheduleId` và `employeeId` không bắt buộc: backend tự tìm lịch hôm nay của người đăng nhập theo ca và khu vực của QR.

Thành công:

```json
{
  "attendanceId": 12, "scheduleId": 4, "action": "CHECK_IN",
  "occurredAt": "2026-10-21T07:55:02", "attendanceStatus": "PRESENT", "lateMinutes": 0,
  "shiftName": "Ca sáng", "areaName": "Quầy thu ngân", "distanceMeters": 12.4,
  "evidenceUrl": "/uploads/evidence/<hash>.jpg", "message": "Check-in thành công, bạn đến đúng giờ."
}
```

Bị từ chối (HTTP 400): `{ "code": "QR_EXPIRED", "message": "Mã QR đã hết hạn..." }`

| code | Ý nghĩa |
| --- | --- |
| `QR_INVALID` | Token không tồn tại |
| `QR_REVOKED` | QR đã bị thu hồi |
| `QR_EXPIRED` | QR hết hạn |
| `QR_WRONG_TYPE` | Dùng QR check-out để check-in (hoặc ngược lại) |
| `QR_REQUIRED` | Ca yêu cầu QR nhưng không gửi |
| `NO_SCHEDULE` | Không có lịch làm hôm nay |
| `SCHEDULE_NOT_ACTIVE` / `NOT_WORK_DATE` | Lịch đã hủy / không phải ngày làm |
| `SCHEDULE_REQUIRED` | Có nhiều ca, không có QR để xác định ca |
| `WRONG_SHIFT` | QR không thuộc ca của nhân viên |
| `INVALID_LOCATION` | QR sai khu vực, hoặc GPS ngoài bán kính khu vực |
| `LOCATION_REQUIRED` / `GPS_INACCURATE` | Ca yêu cầu GPS nhưng không có / sai số > 100 m |
| `CHECK_IN_TOO_EARLY` | Check-in sớm hơn `check_in_early_minutes` |
| `ALREADY_CHECKED_IN` / `ALREADY_CHECKED_OUT` | Đã chấm công rồi |
| `NOT_CHECKED_IN` | Check-out khi chưa check-in |
| `EVIDENCE_REQUIRED` | Ca yêu cầu ảnh nhưng chưa có ảnh |
| `EVIDENCE_NOT_FOUND` / `EVIDENCE_REUSED` | Ảnh chưa upload / ảnh đã dùng cho lần khác |

Trạng thái check-in: quá `allowed_late_minutes` sau giờ bắt đầu ca → `LATE`, ngược lại `PRESENT`.

## 5. Lịch sử

`GET /api/attendance/employees/9/history`

## Dữ liệu demo

Chạy `database/attendance_demo_data.sql` để có sẵn kịch bản cho từng business rule (xem chú thích đầu file).
