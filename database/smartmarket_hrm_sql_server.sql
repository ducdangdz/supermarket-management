/* =========================================================================
   HỆ THỐNG QUẢN LÝ NHÂN SỰ SIÊU THỊ: SMARTMARKET HRM
   Database: SQL Server 2019+
   Mô tả: 12 bảng chuẩn hóa cho phân quyền, chi nhánh, hồ sơ nhân viên,
          sơ đồ mặt bằng, ca làm, phân công, QR động, ảnh bằng chứng & GPS.
   ========================================================================= */

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = N'smartmarket_hrm')
BEGIN
    CREATE DATABASE smartmarket_hrm COLLATE Latin1_General_100_CI_AS_SC_UTF8;
END
GO

USE smartmarket_hrm;
GO

-- 1. BẢNG VAI TRÒ
IF OBJECT_ID(N'dbo.roles', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.roles (
        role_id BIGINT IDENTITY(1,1) PRIMARY KEY,
        role_code VARCHAR(30) NOT NULL,
        role_name NVARCHAR(100) NOT NULL,
        description NVARCHAR(255) NULL,
        created_at DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
        CONSTRAINT UK_roles_code UNIQUE (role_code)
    );

    INSERT INTO dbo.roles (role_code, role_name, description) VALUES
    ('ADMIN', N'Quản trị viên', N'Quản lý toàn bộ hệ thống'),
    ('MANAGER', N'Quản lý chi nhánh', N'Quản lý vận hành và phân công tại chi nhánh'),
    ('HR', N'Nhân sự', N'Quản lý hồ sơ nhân viên và báo cáo chuyên cần'),
    ('EMPLOYEE', N'Nhân viên', N'Nhân viên làm việc tại siêu thị');
END
GO

-- 2. BẢNG CHI NHÁNH
IF OBJECT_ID(N'dbo.branches', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.branches (
        branch_id BIGINT IDENTITY(1,1) PRIMARY KEY,
        branch_code VARCHAR(30) NOT NULL,
        branch_name NVARCHAR(150) NOT NULL,
        address NVARCHAR(255) NOT NULL,
        phone VARCHAR(20) NULL,
        latitude DECIMAL(10,7) NULL,
        longitude DECIMAL(10,7) NULL,
        is_active BIT NOT NULL DEFAULT 1,
        created_at DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
        updated_at DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
        CONSTRAINT UK_branches_code UNIQUE (branch_code),
        CONSTRAINT CHK_branches_lat CHECK (latitude IS NULL OR (latitude BETWEEN -90 AND 90)),
        CONSTRAINT CHK_branches_lng CHECK (longitude IS NULL OR (longitude BETWEEN -180 AND 180))
    );
END
GO

-- 3. BẢNG NHÂN VIÊN
IF OBJECT_ID(N'dbo.employees', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.employees (
        employee_id BIGINT IDENTITY(1,1) PRIMARY KEY,
        role_id BIGINT NOT NULL,
        branch_id BIGINT NULL,
        employee_code VARCHAR(30) NOT NULL,
        full_name NVARCHAR(150) NOT NULL,
        email VARCHAR(150) NOT NULL,
        phone VARCHAR(20) NULL,
        avatar_url VARCHAR(1000) NULL,
        google_sub VARCHAR(255) NULL,
        login_provider VARCHAR(20) NOT NULL DEFAULT 'GOOGLE',
        password_hash VARCHAR(255) NULL,
        employment_status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
        hired_date DATE NULL,
        created_at DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
        updated_at DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
        CONSTRAINT FK_employees_role FOREIGN KEY (role_id) REFERENCES dbo.roles(role_id),
        CONSTRAINT FK_employees_branch FOREIGN KEY (branch_id) REFERENCES dbo.branches(branch_id) ON DELETE SET NULL,
        CONSTRAINT UK_employees_code UNIQUE (employee_code),
        CONSTRAINT UK_employees_email UNIQUE (email),
        CONSTRAINT UK_employees_google_sub UNIQUE (google_sub),
        CONSTRAINT CHK_employees_status CHECK (employment_status IN ('ACTIVE', 'INACTIVE', 'SUSPENDED'))
    );
END
GO

-- 4. BẢNG SƠ ĐỒ MẶT BẰNG
IF OBJECT_ID(N'dbo.floor_plans', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.floor_plans (
        floor_plan_id BIGINT IDENTITY(1,1) PRIMARY KEY,
        branch_id BIGINT NOT NULL,
        floor_number TINYINT NOT NULL DEFAULT 1,
        floor_name NVARCHAR(100) NOT NULL,
        image_url VARCHAR(1000) NOT NULL,
        image_width INT NULL,
        image_height INT NULL,
        is_active BIT NOT NULL DEFAULT 1,
        created_at DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
        updated_at DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
        CONSTRAINT FK_floor_plans_branch FOREIGN KEY (branch_id) REFERENCES dbo.branches(branch_id) ON DELETE CASCADE,
        CONSTRAINT UK_floor_plan_branch_floor UNIQUE (branch_id, floor_number)
    );
END
GO

-- 5. BẢNG KHU VỰC LÀM VIỆC TRÊN SƠ ĐỒ
IF OBJECT_ID(N'dbo.work_areas', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.work_areas (
        work_area_id BIGINT IDENTITY(1,1) PRIMARY KEY,
        floor_plan_id BIGINT NOT NULL,
        area_code VARCHAR(30) NOT NULL,
        area_name NVARCHAR(150) NOT NULL,
        area_type VARCHAR(30) NOT NULL DEFAULT 'OTHER',
        max_employees SMALLINT NULL,
        map_x DECIMAL(7,2) NOT NULL,
        map_y DECIMAL(7,2) NOT NULL,
        map_width DECIMAL(7,2) NULL,
        map_height DECIMAL(7,2) NULL,
        polygon_data NVARCHAR(MAX) NULL,
        latitude DECIMAL(10,7) NULL,
        longitude DECIMAL(10,7) NULL,
        radius_meters INT NULL,
        is_active BIT NOT NULL DEFAULT 1,
        created_at DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
        updated_at DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
        CONSTRAINT FK_work_areas_floor_plan FOREIGN KEY (floor_plan_id) REFERENCES dbo.floor_plans(floor_plan_id) ON DELETE CASCADE,
        CONSTRAINT UK_work_areas_floor_code UNIQUE (floor_plan_id, area_code),
        CONSTRAINT CHK_work_areas_x CHECK (map_x BETWEEN 0 AND 100),
        CONSTRAINT CHK_work_areas_y CHECK (map_y BETWEEN 0 AND 100),
        CONSTRAINT CHK_work_areas_type CHECK (area_type IN ('CASHIER', 'WAREHOUSE', 'FRESH_FOOD', 'GROCERY', 'SECURITY', 'OFFICE', 'CUSTOMER_SERVICE', 'OTHER'))
    );
END
GO

-- 6. BẢNG CA LÀM VIỆC
IF OBJECT_ID(N'dbo.shifts', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.shifts (
        shift_id BIGINT IDENTITY(1,1) PRIMARY KEY,
        branch_id BIGINT NOT NULL,
        shift_code VARCHAR(30) NOT NULL,
        shift_name NVARCHAR(100) NOT NULL,
        start_time TIME(0) NOT NULL,
        end_time TIME(0) NOT NULL,
        check_in_early_minutes SMALLINT NOT NULL DEFAULT 30,
        allowed_late_minutes SMALLINT NOT NULL DEFAULT 15,
        allowed_early_checkout_minutes SMALLINT NOT NULL DEFAULT 0,
        require_qr BIT NOT NULL DEFAULT 1,
        require_evidence BIT NOT NULL DEFAULT 0,
        require_location BIT NOT NULL DEFAULT 0,
        is_active BIT NOT NULL DEFAULT 1,
        created_at DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
        updated_at DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
        CONSTRAINT FK_shifts_branch FOREIGN KEY (branch_id) REFERENCES dbo.branches(branch_id) ON DELETE CASCADE,
        CONSTRAINT UK_shifts_branch_code UNIQUE (branch_id, shift_code),
        CONSTRAINT CHK_shifts_time CHECK (start_time <> end_time)
    );
END
GO

-- 7. BẢNG PHÂN CÔNG LỊCH LÀM
IF OBJECT_ID(N'dbo.work_schedules', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.work_schedules (
        schedule_id BIGINT IDENTITY(1,1) PRIMARY KEY,
        employee_id BIGINT NOT NULL,
        shift_id BIGINT NOT NULL,
        work_area_id BIGINT NOT NULL,
        work_date DATE NOT NULL,
        schedule_status VARCHAR(20) NOT NULL DEFAULT 'SCHEDULED',
        assigned_by BIGINT NULL,
        note NVARCHAR(500) NULL,
        created_at DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
        updated_at DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
        CONSTRAINT FK_work_schedules_employee FOREIGN KEY (employee_id) REFERENCES dbo.employees(employee_id),
        CONSTRAINT FK_work_schedules_shift FOREIGN KEY (shift_id) REFERENCES dbo.shifts(shift_id),
        CONSTRAINT FK_work_schedules_work_area FOREIGN KEY (work_area_id) REFERENCES dbo.work_areas(work_area_id),
        CONSTRAINT FK_work_schedules_assigned_by FOREIGN KEY (assigned_by) REFERENCES dbo.employees(employee_id),
        CONSTRAINT UK_schedule_employee_shift_date UNIQUE (employee_id, shift_id, work_date),
        CONSTRAINT CHK_schedule_status CHECK (schedule_status IN ('SCHEDULED', 'CANCELLED', 'COMPLETED', 'ABSENT'))
    );
END
GO

-- 8. BẢNG PHIÊN QR CHẤM CÔNG
IF OBJECT_ID(N'dbo.qr_sessions', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.qr_sessions (
        qr_session_id BIGINT IDENTITY(1,1) PRIMARY KEY,
        shift_id BIGINT NOT NULL,
        work_area_id BIGINT NOT NULL,
        session_type VARCHAR(20) NOT NULL,
        token_hash CHAR(64) NOT NULL,
        issued_at DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
        expires_at DATETIME2(0) NOT NULL,
        issued_by BIGINT NULL,
        is_revoked BIT NOT NULL DEFAULT 0,
        created_at DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
        CONSTRAINT FK_qr_sessions_shift FOREIGN KEY (shift_id) REFERENCES dbo.shifts(shift_id),
        CONSTRAINT FK_qr_sessions_work_area FOREIGN KEY (work_area_id) REFERENCES dbo.work_areas(work_area_id),
        CONSTRAINT FK_qr_sessions_issued_by FOREIGN KEY (issued_by) REFERENCES dbo.employees(employee_id),
        CONSTRAINT UK_qr_sessions_token_hash UNIQUE (token_hash),
        CONSTRAINT CHK_qr_sessions_type CHECK (session_type IN ('CHECK_IN', 'CHECK_OUT'))
    );
END
GO

-- 9. BẢNG BẢN GHI CHẤM CÔNG
IF OBJECT_ID(N'dbo.attendance_records', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.attendance_records (
        attendance_id BIGINT IDENTITY(1,1) PRIMARY KEY,
        schedule_id BIGINT NOT NULL,
        employee_id BIGINT NOT NULL,
        check_in_qr_session_id BIGINT NULL,
        check_out_qr_session_id BIGINT NULL,
        check_in_at DATETIME2(0) NULL,
        check_out_at DATETIME2(0) NULL,
        check_in_latitude DECIMAL(10,7) NULL,
        check_in_longitude DECIMAL(10,7) NULL,
        check_in_accuracy_meters DECIMAL(8,2) NULL,
        check_out_latitude DECIMAL(10,7) NULL,
        check_out_longitude DECIMAL(10,7) NULL,
        check_out_accuracy_meters DECIMAL(8,2) NULL,
        attendance_status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
        verification_status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
        verified_by BIGINT NULL,
        verified_at DATETIME2(0) NULL,
        note NVARCHAR(500) NULL,
        created_at DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
        updated_at DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
        CONSTRAINT FK_attendance_schedule FOREIGN KEY (schedule_id) REFERENCES dbo.work_schedules(schedule_id),
        CONSTRAINT FK_attendance_employee FOREIGN KEY (employee_id) REFERENCES dbo.employees(employee_id),
        CONSTRAINT FK_attendance_checkin_qr FOREIGN KEY (check_in_qr_session_id) REFERENCES dbo.qr_sessions(qr_session_id),
        CONSTRAINT FK_attendance_checkout_qr FOREIGN KEY (check_out_qr_session_id) REFERENCES dbo.qr_sessions(qr_session_id),
        CONSTRAINT FK_attendance_verified_by FOREIGN KEY (verified_by) REFERENCES dbo.employees(employee_id),
        CONSTRAINT UK_attendance_schedule UNIQUE (schedule_id),
        CONSTRAINT CHK_attendance_status CHECK (attendance_status IN ('PENDING', 'PRESENT', 'LATE', 'ABSENT', 'INVALID_LOCATION', 'REJECTED')),
        CONSTRAINT CHK_attendance_verif CHECK (verification_status IN ('PENDING', 'VERIFIED', 'REJECTED'))
    );
END
GO

-- 10. BẢNG ẢNH BẰNG CHỨNG
IF OBJECT_ID(N'dbo.attendance_evidence', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.attendance_evidence (
        evidence_id BIGINT IDENTITY(1,1) PRIMARY KEY,
        attendance_id BIGINT NOT NULL,
        evidence_type VARCHAR(30) NOT NULL,
        file_url VARCHAR(1000) NOT NULL,
        file_hash CHAR(64) NOT NULL,
        captured_at DATETIME2(0) NULL,
        latitude DECIMAL(10,7) NULL,
        longitude DECIMAL(10,7) NULL,
        device_info NVARCHAR(500) NULL,
        review_status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
        reviewed_by BIGINT NULL,
        reviewed_at DATETIME2(0) NULL,
        created_at DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
        CONSTRAINT FK_attendance_evidence_record FOREIGN KEY (attendance_id) REFERENCES dbo.attendance_records(attendance_id) ON DELETE CASCADE,
        CONSTRAINT FK_attendance_evidence_reviewer FOREIGN KEY (reviewed_by) REFERENCES dbo.employees(employee_id),
        CONSTRAINT UK_evidence_file_hash UNIQUE (file_hash),
        CONSTRAINT CHK_evidence_type CHECK (evidence_type IN ('CHECK_IN_PHOTO', 'CHECK_OUT_PHOTO', 'OTHER')),
        CONSTRAINT CHK_evidence_review CHECK (review_status IN ('PENDING', 'APPROVED', 'REJECTED'))
    );
END
GO

-- 11. BẢNG PHIÊN GPS LIÊN TỤC (TÙY CHỌN)
IF OBJECT_ID(N'dbo.location_sessions', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.location_sessions (
        location_session_id BIGINT IDENTITY(1,1) PRIMARY KEY,
        schedule_id BIGINT NOT NULL,
        employee_id BIGINT NOT NULL,
        started_at DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
        ended_at DATETIME2(0) NULL,
        session_status VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
        consent_version VARCHAR(30) NOT NULL,
        created_at DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
        CONSTRAINT FK_location_sessions_schedule FOREIGN KEY (schedule_id) REFERENCES dbo.work_schedules(schedule_id),
        CONSTRAINT FK_location_sessions_employee FOREIGN KEY (employee_id) REFERENCES dbo.employees(employee_id),
        CONSTRAINT CHK_location_session_status CHECK (session_status IN ('ACTIVE', 'STOPPED', 'EXPIRED'))
    );
END
GO

-- 12. BẢNG NHẬT KÝ TỌA ĐỘ GPS (TÙY CHỌN)
IF OBJECT_ID(N'dbo.location_logs', N'U') IS NULL
BEGIN
    CREATE TABLE dbo.location_logs (
        location_log_id BIGINT IDENTITY(1,1) PRIMARY KEY,
        location_session_id BIGINT NOT NULL,
        recorded_at DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
        latitude DECIMAL(10,7) NOT NULL,
        longitude DECIMAL(10,7) NOT NULL,
        accuracy_meters DECIMAL(8,2) NULL,
        speed_mps DECIMAL(8,2) NULL,
        is_mocked BIT NOT NULL DEFAULT 0,
        created_at DATETIME2(0) NOT NULL DEFAULT SYSDATETIME(),
        CONSTRAINT FK_location_logs_session FOREIGN KEY (location_session_id) REFERENCES dbo.location_sessions(location_session_id) ON DELETE CASCADE
    );
END
GO
