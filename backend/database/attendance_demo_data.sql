/*
  Dữ liệu demo nghiệp vụ chấm công QR + GPS + ảnh bằng chứng.
  Chạy SAU schema script và sample_data.sql. Chạy lại an toàn: mỗi lần chạy sẽ
  dời giờ ca demo theo giờ hiện tại và xóa chấm công hôm nay của ca demo.

  Trước khi chạy: sửa @lat/@lng thành tọa độ nơi bạn demo (lấy từ Google Maps).

  Kịch bản demo (tài khoản Google phải trùng email trong bảng employees):
  - EMP001 Phạm An   : ca DEMO_ONTIME @ Quầy thu ngân → PRESENT, ca yêu cầu ảnh (không chụp → EVIDENCE_REQUIRED).
  - EMP002 Vũ Bình   : ca DEMO_LATE   @ Quầy thu ngân → LATE (ca bắt đầu 30 phút trước).
  - EMP003 Đỗ Chi    : ca DEMO_ONTIME @ Kho hàng
                       + quét QR của Quầy thu ngân  → INVALID_LOCATION (sai khu vực).
                       + quét QR của Kho hàng       → INVALID_LOCATION (GPS cách kho ~2 km).
  - EMP004 Ngô Dũng  : không có lịch hôm nay → NO_SCHEDULE.
  - Bất kỳ ai check-out trước khi check-in → NOT_CHECKED_IN.
  - QR hết hạn: tạo QR thời hạn 30 giây rồi đợi → QR_EXPIRED.
  - QR thu hồi: UPDATE dbo.qr_sessions SET is_revoked = 1 WHERE qr_session_id = <id>; → QR_REVOKED.
*/
USE smartmarket_hrm;
GO

DECLARE @lat DECIMAL(10,7) = 10.7769000;
DECLARE @lng DECIMAL(10,7) = 106.7009000;

DECLARE @branchId BIGINT = (SELECT branch_id FROM dbo.branches WHERE branch_code = 'SM001');
DECLARE @today DATE = CAST(SYSDATETIME() AS DATE);
DECLARE @now TIME(0) = CAST(SYSDATETIME() AS TIME(0));
DECLARE @onTimeStart TIME(0) = DATEADD(MINUTE, 10, @now);
DECLARE @lateStart TIME(0) = DATEADD(MINUTE, -30, @now);

-- 1. Tọa độ chi nhánh và khu vực (Kho hàng đặt lệch ~2.2 km để demo GPS ngoài bán kính)
UPDATE dbo.branches SET latitude = @lat, longitude = @lng WHERE branch_id = @branchId;

UPDATE wa SET latitude = @lat, longitude = @lng, radius_meters = 150
FROM dbo.work_areas wa
JOIN dbo.floor_plans fp ON fp.floor_plan_id = wa.floor_plan_id
WHERE fp.branch_id = @branchId AND wa.area_code IN ('CASHIER', 'FRESH');

UPDATE wa SET latitude = @lat + 0.0200000, longitude = @lng, radius_meters = 100
FROM dbo.work_areas wa
JOIN dbo.floor_plans fp ON fp.floor_plan_id = wa.floor_plan_id
WHERE fp.branch_id = @branchId AND wa.area_code = 'WAREHOUSE';

-- 2. Hai ca demo, giờ bắt đầu tính theo giờ hiện tại
IF NOT EXISTS (SELECT 1 FROM dbo.shifts WHERE branch_id = @branchId AND shift_code = 'DEMO_ONTIME')
    INSERT INTO dbo.shifts (branch_id, shift_code, shift_name, start_time, end_time, check_in_early_minutes,
                            allowed_late_minutes, require_qr, require_evidence, require_location)
    VALUES (@branchId, 'DEMO_ONTIME', N'Ca demo đúng giờ', @onTimeStart, DATEADD(HOUR, 4, @onTimeStart), 30, 15, 1, 1, 1);
ELSE
    UPDATE dbo.shifts
    SET start_time = @onTimeStart, end_time = DATEADD(HOUR, 4, @onTimeStart), check_in_early_minutes = 30,
        allowed_late_minutes = 15, require_qr = 1, require_evidence = 1, require_location = 1, is_active = 1
    WHERE branch_id = @branchId AND shift_code = 'DEMO_ONTIME';

IF NOT EXISTS (SELECT 1 FROM dbo.shifts WHERE branch_id = @branchId AND shift_code = 'DEMO_LATE')
    INSERT INTO dbo.shifts (branch_id, shift_code, shift_name, start_time, end_time, check_in_early_minutes,
                            allowed_late_minutes, require_qr, require_evidence, require_location)
    VALUES (@branchId, 'DEMO_LATE', N'Ca demo đi muộn', @lateStart, DATEADD(HOUR, 4, @lateStart), 30, 15, 1, 0, 1);
ELSE
    UPDATE dbo.shifts
    SET start_time = @lateStart, end_time = DATEADD(HOUR, 4, @lateStart), check_in_early_minutes = 30,
        allowed_late_minutes = 15, require_qr = 1, require_evidence = 0, require_location = 1, is_active = 1
    WHERE branch_id = @branchId AND shift_code = 'DEMO_LATE';

-- 3. Nhân viên không có lịch hôm nay
DECLARE @employeeRole BIGINT = (SELECT role_id FROM dbo.roles WHERE role_code = 'EMPLOYEE');
IF NOT EXISTS (SELECT 1 FROM dbo.employees WHERE employee_code = 'EMP004')
    INSERT INTO dbo.employees (role_id, branch_id, employee_code, full_name, email, phone, login_provider, employment_status)
    VALUES (@employeeRole, @branchId, 'EMP004', N'Ngô Dũng', 'dung@smartmarket.local', '0900000007', 'GOOGLE', 'ACTIVE');

-- 4. Phân công lịch demo
DECLARE @managerId BIGINT = (SELECT employee_id FROM dbo.employees WHERE employee_code = 'MNG001');
DECLARE @employee1 BIGINT = (SELECT employee_id FROM dbo.employees WHERE employee_code = 'EMP001');
DECLARE @employee2 BIGINT = (SELECT employee_id FROM dbo.employees WHERE employee_code = 'EMP002');
DECLARE @employee3 BIGINT = (SELECT employee_id FROM dbo.employees WHERE employee_code = 'EMP003');
DECLARE @onTimeShift BIGINT = (SELECT shift_id FROM dbo.shifts WHERE branch_id = @branchId AND shift_code = 'DEMO_ONTIME');
DECLARE @lateShift BIGINT = (SELECT shift_id FROM dbo.shifts WHERE branch_id = @branchId AND shift_code = 'DEMO_LATE');
DECLARE @cashier BIGINT = (SELECT wa.work_area_id FROM dbo.work_areas wa JOIN dbo.floor_plans fp ON fp.floor_plan_id = wa.floor_plan_id
                           WHERE fp.branch_id = @branchId AND wa.area_code = 'CASHIER');
DECLARE @warehouse BIGINT = (SELECT wa.work_area_id FROM dbo.work_areas wa JOIN dbo.floor_plans fp ON fp.floor_plan_id = wa.floor_plan_id
                             WHERE fp.branch_id = @branchId AND wa.area_code = 'WAREHOUSE');

-- Xóa chấm công hôm nay của ca demo để demo lại từ đầu (ảnh bằng chứng bị xóa theo ON DELETE CASCADE)
DELETE ar
FROM dbo.attendance_records ar
JOIN dbo.work_schedules ws ON ws.schedule_id = ar.schedule_id
WHERE ws.work_date = @today AND ws.shift_id IN (@onTimeShift, @lateShift);

IF NOT EXISTS (SELECT 1 FROM dbo.work_schedules WHERE employee_id = @employee1 AND shift_id = @onTimeShift AND work_date = @today)
    INSERT INTO dbo.work_schedules (employee_id, shift_id, work_area_id, work_date, assigned_by)
    VALUES (@employee1, @onTimeShift, @cashier, @today, @managerId);

IF NOT EXISTS (SELECT 1 FROM dbo.work_schedules WHERE employee_id = @employee2 AND shift_id = @lateShift AND work_date = @today)
    INSERT INTO dbo.work_schedules (employee_id, shift_id, work_area_id, work_date, assigned_by)
    VALUES (@employee2, @lateShift, @cashier, @today, @managerId);

IF NOT EXISTS (SELECT 1 FROM dbo.work_schedules WHERE employee_id = @employee3 AND shift_id = @onTimeShift AND work_date = @today)
    INSERT INTO dbo.work_schedules (employee_id, shift_id, work_area_id, work_date, assigned_by)
    VALUES (@employee3, @onTimeShift, @warehouse, @today, @managerId);

UPDATE dbo.work_schedules SET schedule_status = 'SCHEDULED'
WHERE work_date = @today AND shift_id IN (@onTimeShift, @lateShift);
GO
