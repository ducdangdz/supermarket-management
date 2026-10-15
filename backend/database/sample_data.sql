/* Run once in SQL Server after the schema script. Safe to run again. */
USE smartmarket_hrm;
GO

IF NOT EXISTS (SELECT 1 FROM dbo.branches WHERE branch_code = 'SM001')
INSERT INTO dbo.branches (branch_code, branch_name, address, phone, is_active)
VALUES ('SM001', N'SmartMarket Quận 1', N'123 Nguyễn Huệ, Quận 1, TP.HCM', '02812345678', 1);
GO

DECLARE @branchId BIGINT = (SELECT branch_id FROM dbo.branches WHERE branch_code = 'SM001');

IF NOT EXISTS (SELECT 1 FROM dbo.floor_plans WHERE branch_id = @branchId AND floor_number = 1)
INSERT INTO dbo.floor_plans (branch_id, floor_number, floor_name, image_url, is_active)
VALUES (@branchId, 1, N'Tầng trệt', N'https://example.invalid/floor-plan-1.png', 1);

DECLARE @floorPlanId BIGINT = (SELECT floor_plan_id FROM dbo.floor_plans WHERE branch_id = @branchId AND floor_number = 1);

IF NOT EXISTS (SELECT 1 FROM dbo.work_areas WHERE floor_plan_id = @floorPlanId AND area_code = 'CASHIER')
INSERT INTO dbo.work_areas (floor_plan_id, area_code, area_name, area_type, max_employees, map_x, map_y, map_width, map_height)
VALUES (@floorPlanId, 'CASHIER', N'Quầy thu ngân', 'CASHIER', 3, 15, 25, 20, 18);

IF NOT EXISTS (SELECT 1 FROM dbo.work_areas WHERE floor_plan_id = @floorPlanId AND area_code = 'WAREHOUSE')
INSERT INTO dbo.work_areas (floor_plan_id, area_code, area_name, area_type, max_employees, map_x, map_y, map_width, map_height)
VALUES (@floorPlanId, 'WAREHOUSE', N'Kho hàng', 'WAREHOUSE', 2, 70, 65, 22, 20);

IF NOT EXISTS (SELECT 1 FROM dbo.work_areas WHERE floor_plan_id = @floorPlanId AND area_code = 'FRESH')
INSERT INTO dbo.work_areas (floor_plan_id, area_code, area_name, area_type, max_employees, map_x, map_y, map_width, map_height)
VALUES (@floorPlanId, 'FRESH', N'Quầy thực phẩm tươi', 'FRESH_FOOD', 2, 42, 25, 20, 18);

IF NOT EXISTS (SELECT 1 FROM dbo.shifts WHERE branch_id = @branchId AND shift_code = 'MORNING')
INSERT INTO dbo.shifts (branch_id, shift_code, shift_name, start_time, end_time, require_qr, require_evidence, require_location)
VALUES (@branchId, 'MORNING', N'Ca sáng', '07:00', '15:00', 1, 0, 0);

IF NOT EXISTS (SELECT 1 FROM dbo.shifts WHERE branch_id = @branchId AND shift_code = 'AFTERNOON')
INSERT INTO dbo.shifts (branch_id, shift_code, shift_name, start_time, end_time, require_qr, require_evidence, require_location)
VALUES (@branchId, 'AFTERNOON', N'Ca chiều', '14:00', '22:00', 1, 1, 0);

DECLARE @adminRole BIGINT = (SELECT role_id FROM dbo.roles WHERE role_code = 'ADMIN');
DECLARE @managerRole BIGINT = (SELECT role_id FROM dbo.roles WHERE role_code = 'MANAGER');
DECLARE @hrRole BIGINT = (SELECT role_id FROM dbo.roles WHERE role_code = 'HR');
DECLARE @employeeRole BIGINT = (SELECT role_id FROM dbo.roles WHERE role_code = 'EMPLOYEE');

IF NOT EXISTS (SELECT 1 FROM dbo.employees WHERE employee_code = 'ADM001')
INSERT INTO dbo.employees (role_id, branch_id, employee_code, full_name, email, phone, login_provider, employment_status)
VALUES (@adminRole, @branchId, 'ADM001', N'Nguyễn Minh Admin', 'admin@smartmarket.local', '0900000001', 'GOOGLE', 'ACTIVE');

IF NOT EXISTS (SELECT 1 FROM dbo.employees WHERE employee_code = 'MNG001')
INSERT INTO dbo.employees (role_id, branch_id, employee_code, full_name, email, phone, login_provider, employment_status)
VALUES (@managerRole, @branchId, 'MNG001', N'Trần Hải Manager', 'manager@smartmarket.local', '0900000002', 'GOOGLE', 'ACTIVE');

IF NOT EXISTS (SELECT 1 FROM dbo.employees WHERE employee_code = 'HR001')
INSERT INTO dbo.employees (role_id, branch_id, employee_code, full_name, email, phone, login_provider, employment_status)
VALUES (@hrRole, @branchId, 'HR001', N'Lê Thu Nhân sự', 'hr@smartmarket.local', '0900000003', 'GOOGLE', 'ACTIVE');

IF NOT EXISTS (SELECT 1 FROM dbo.employees WHERE employee_code = 'EMP001')
INSERT INTO dbo.employees (role_id, branch_id, employee_code, full_name, email, phone, login_provider, employment_status)
VALUES (@employeeRole, @branchId, 'EMP001', N'Phạm An', 'an@smartmarket.local', '0900000004', 'GOOGLE', 'ACTIVE');

IF NOT EXISTS (SELECT 1 FROM dbo.employees WHERE employee_code = 'EMP002')
INSERT INTO dbo.employees (role_id, branch_id, employee_code, full_name, email, phone, login_provider, employment_status)
VALUES (@employeeRole, @branchId, 'EMP002', N'Vũ Bình', 'binh@smartmarket.local', '0900000005', 'GOOGLE', 'ACTIVE');

IF NOT EXISTS (SELECT 1 FROM dbo.employees WHERE employee_code = 'EMP003')
INSERT INTO dbo.employees (role_id, branch_id, employee_code, full_name, email, phone, login_provider, employment_status)
VALUES (@employeeRole, @branchId, 'EMP003', N'Đỗ Chi', 'chi@smartmarket.local', '0900000006', 'GOOGLE', 'ACTIVE');
GO

DECLARE @managerId BIGINT = (SELECT employee_id FROM dbo.employees WHERE employee_code = 'MNG001');
DECLARE @employee1 BIGINT = (SELECT employee_id FROM dbo.employees WHERE employee_code = 'EMP001');
DECLARE @employee2 BIGINT = (SELECT employee_id FROM dbo.employees WHERE employee_code = 'EMP002');
DECLARE @employee3 BIGINT = (SELECT employee_id FROM dbo.employees WHERE employee_code = 'EMP003');
DECLARE @morningShift BIGINT = (SELECT shift_id FROM dbo.shifts WHERE shift_code = 'MORNING');
DECLARE @afternoonShift BIGINT = (SELECT shift_id FROM dbo.shifts WHERE shift_code = 'AFTERNOON');
DECLARE @cashier BIGINT = (SELECT work_area_id FROM dbo.work_areas WHERE area_code = 'CASHIER');
DECLARE @warehouse BIGINT = (SELECT work_area_id FROM dbo.work_areas WHERE area_code = 'WAREHOUSE');
DECLARE @fresh BIGINT = (SELECT work_area_id FROM dbo.work_areas WHERE area_code = 'FRESH');
DECLARE @today DATE = CAST(GETDATE() AS DATE);

IF NOT EXISTS (SELECT 1 FROM dbo.work_schedules WHERE employee_id = @employee1 AND shift_id = @morningShift AND work_date = @today)
INSERT INTO dbo.work_schedules (employee_id, shift_id, work_area_id, work_date, assigned_by)
VALUES (@employee1, @morningShift, @cashier, @today, @managerId);

IF NOT EXISTS (SELECT 1 FROM dbo.work_schedules WHERE employee_id = @employee2 AND shift_id = @morningShift AND work_date = @today)
INSERT INTO dbo.work_schedules (employee_id, shift_id, work_area_id, work_date, assigned_by)
VALUES (@employee2, @morningShift, @warehouse, @today, @managerId);

IF NOT EXISTS (SELECT 1 FROM dbo.work_schedules WHERE employee_id = @employee3 AND shift_id = @afternoonShift AND work_date = @today)
INSERT INTO dbo.work_schedules (employee_id, shift_id, work_area_id, work_date, assigned_by)
VALUES (@employee3, @afternoonShift, @fresh, @today, @managerId);
GO
