# API chấm công QR

## 1. Tạo QR để demo

`POST /api/management/qr-sessions`

```json
{
  "shiftId": 1,
  "workAreaId": 1,
  "sessionType": "CHECK_IN",
  "expiresInSeconds": 60,
  "issuedBy": 7
}
```

Kết quả trả về `token`. Trong ứng dụng thật, đưa token này vào QR; backend chỉ lưu SHA-256 của token.

## 2. Check-in

`POST /api/attendance/check-in`

```json
{
  "scheduleId": 4,
  "employeeId": 9,
  "qrToken": "TOKEN_TU_API_TAO_QR",
  "latitude": 10.7769,
  "longitude": 106.7009,
  "accuracyMeters": 15
}
```

## 3. Check-out

Tạo QR loại `CHECK_OUT`, sau đó gọi `POST /api/attendance/check-out` với body giống check-in.

## 4. Lịch sử

`GET /api/attendance/employees/9/history`
