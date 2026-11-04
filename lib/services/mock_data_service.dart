import '../core/network/team_api.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';

class MockDataService extends ChangeNotifier {
  final TeamApi? remoteApi;
  final int? sessionBranchId;
  List<Branch> _availableBranches = [];
  List<Branch> get branches => isRemote ? _availableBranches : [_currentBranch];
  bool get isRemote => remoteApi != null;
  String? syncError;
  bool syncing = false;

  // Current active role for RBAC & Demo (ADMIN, MANAGER, HR, EMPLOYEE)
  String _currentRoleCode = 'ADMIN';
  int _currentLoggedInEmployeeId =
      2; // Default demo employee: Nguyễn Thị Thu Ngân (ID: 2)

  String get currentRoleCode => _currentRoleCode;
  int get currentLoggedInEmployeeId => _currentLoggedInEmployeeId;

  void setCurrentRole(String roleCode, {int? employeeId}) {
    if (isRemote && _roleLocked) return;
    _currentRoleCode = roleCode;
    if (employeeId != null) {
      _currentLoggedInEmployeeId = employeeId;
    } else if (roleCode == 'EMPLOYEE') {
      _currentLoggedInEmployeeId = 2;
    }
    notifyListeners();
  }

  // 1. Roles
  final List<Role> _roles = [
    Role(roleId: 1, roleCode: 'ADMIN', roleName: 'Quản trị viên'),
    Role(roleId: 2, roleCode: 'MANAGER', roleName: 'Quản lý chi nhánh'),
    Role(roleId: 3, roleCode: 'HR', roleName: 'Nhân sự'),
    Role(roleId: 4, roleCode: 'EMPLOYEE', roleName: 'Nhân viên siêu thị'),
  ];

  // 2. Branch
  Branch _currentBranch = Branch(
    branchId: 1,
    branchCode: 'SM_Q1',
    branchName: 'SmartMarket - Quận 1 (Central)',
    address: '123 Nguyễn Huệ, P. Bến Nghé, Quận 1, TP.HCM',
    phone: '028 3822 1234',
    latitude: 10.7745123,
    longitude: 106.7028123,
  );

  // 3. Employees
  late List<Employee> _employees;

  // 4. Floor Plans & Work Areas
  late FloorPlan _currentFloorPlan;
  late List<WorkArea> _workAreas;

  // 5. Shifts
  late List<Shift> _shifts;

  // 6. Work Schedules
  late List<WorkSchedule> _workSchedules;

  // 7. Attendance Records
  late List<AttendanceRecord> _attendanceRecords;

  bool _roleLocked = false;
  MockDataService({this.remoteApi, this.sessionBranchId, String? roleCode}) {
    if (remoteApi == null) {
      _initData();
    } else {
      _employees = [];
      _workAreas = [];
      _shifts = [];
      _workSchedules = [];
      _attendanceRecords = [];
      _roles.clear();
      _currentBranch = Branch(
        branchId: 0,
        branchCode: '',
        branchName: 'Chưa có chi nhánh',
        address: '',
      );
      _currentFloorPlan = FloorPlan(
        floorPlanId: 0,
        branchId: 0,
        floorNumber: 0,
        floorName: 'Chưa có mặt bằng',
        imageUrl: '',
      );
      _currentRoleCode = roleCode ?? 'EMPLOYEE';
      _currentLoggedInEmployeeId = remoteApi!.employeeId;
      _roleLocked = true;
    }
  }
  Future<void> refresh() async {
    if (remoteApi == null) return;
    final raw = await remoteApi!.request('/management/team-data') as Map;
    List<Map<String, dynamic>> rows(String k) =>
        (raw[k] as List).map((e) => Map<String, dynamic>.from(e)).toList();
    int n(dynamic v) => (v as num).toInt();
    int? ni(dynamic v) => v == null ? null : n(v);
    double? d(dynamic v) => v == null ? null : (v as num).toDouble();
    DateTime? dt(dynamic v) => v == null ? null : DateTime.parse(v.toString());
    bool b(dynamic v) => v == true || v == 1;
    _roles
      ..clear()
      ..addAll(
        rows('roles').map(
          (x) => Role(
            roleId: n(x['role_id']),
            roleCode: x['role_code'],
            roleName: x['role_name'],
          ),
        ),
      );
    final branches = rows('branches');
    _availableBranches = branches
        .map(
          (x) => Branch(
            branchId: n(x['branch_id']),
            branchCode: x['branch_code'],
            branchName: x['branch_name'],
            address: x['address'] ?? '',
            isActive: b(x['is_active']),
          ),
        )
        .toList();
    final selected = branches
        .where((x) => x['branch_id'] == sessionBranchId)
        .toList();
    // Staff without an assigned branch can inspect data, but cannot silently create in an arbitrary branch.
    if (selected.isNotEmpty ||
        (_currentRoleCode == 'ADMIN' && branches.isNotEmpty)) {
      final x = selected.isNotEmpty ? selected.first : branches.first;
      _currentBranch = Branch(
        branchId: n(x['branch_id']),
        branchCode: x['branch_code'],
        branchName: x['branch_name'],
        address: x['address'] ?? '',
        phone: x['phone'],
        latitude: d(x['latitude']),
        longitude: d(x['longitude']),
        isActive: b(x['is_active']),
      );
    }
    _employees = rows('employees')
        .map(
          (x) => Employee(
            employeeId: n(x['employee_id']),
            roleId: n(x['role_id']),
            branchId: ni(x['branch_id']),
            employeeCode: x['employee_code'],
            fullName: x['full_name'],
            email: x['email'],
            phone: x['phone'],
            avatarUrl: x['avatar_url'],
            employmentStatus: x['employment_status'],
            hiredDate: dt(x['hired_date']),
          ),
        )
        .toList();
    final floors = rows(
      'floors',
    ).where((x) => x['branch_id'] == _currentBranch.branchId).toList();
    if (floors.isNotEmpty) {
      final x = floors.first;
      _currentFloorPlan = FloorPlan(
        floorPlanId: n(x['floor_plan_id']),
        branchId: n(x['branch_id']),
        floorNumber: n(x['floor_number']),
        floorName: x['floor_name'],
        imageUrl: x['image_url'],
        imageWidth: ni(x['image_width']),
        imageHeight: ni(x['image_height']),
      );
    }
    _workAreas = rows('areas')
        .map(
          (x) => WorkArea(
            workAreaId: n(x['work_area_id']),
            floorPlanId: n(x['floor_plan_id']),
            areaCode: x['area_code'],
            areaName: x['area_name'],
            areaType: x['area_type'],
            maxEmployees: ni(x['max_employees']),
            mapX: d(x['map_x']) ?? 0,
            mapY: d(x['map_y']) ?? 0,
            mapWidth: d(x['map_width']),
            mapHeight: d(x['map_height']),
            latitude: d(x['latitude']),
            longitude: d(x['longitude']),
            radiusMeters: ni(x['radius_meters']),
            isActive: b(x['is_active']),
          ),
        )
        .toList();
    _shifts = rows('shifts')
        .map(
          (x) => Shift(
            shiftId: n(x['shift_id']),
            branchId: n(x['branch_id']),
            shiftCode: x['shift_code'],
            shiftName: x['shift_name'],
            startTime: x['start_time'],
            endTime: x['end_time'],
            checkInEarlyMinutes: n(x['check_in_early_minutes']),
            allowedLateMinutes: n(x['allowed_late_minutes']),
            allowedEarlyCheckoutMinutes: n(x['allowed_early_checkout_minutes']),
            requireQr: b(x['require_qr']),
            requireEvidence: b(x['require_evidence']),
            requireLocation: b(x['require_location']),
            isActive: b(x['is_active']),
          ),
        )
        .toList();
    _workSchedules = rows('schedules')
        .map(
          (x) => WorkSchedule(
            scheduleId: n(x['schedule_id']),
            employeeId: n(x['employee_id']),
            shiftId: n(x['shift_id']),
            workAreaId: n(x['work_area_id']),
            workDate: dt(x['work_date'])!,
            scheduleStatus: x['schedule_status'],
            assignedBy: ni(x['assigned_by']),
            note: x['note'],
          ),
        )
        .toList();
    final evidence = rows('evidence');
    _attendanceRecords = rows('attendance').map((x) {
      final es = evidence
          .where((e) => e['attendance_id'] == x['attendance_id'])
          .toList();
      AttendanceEvidence? ev;
      if (es.isNotEmpty) {
        final e = es.first;
        ev = AttendanceEvidence(
          evidenceId: n(e['evidence_id']),
          attendanceId: n(e['attendance_id']),
          evidenceType: e['evidence_type'],
          fileUrl: e['file_url'],
          fileHash: e['file_hash'],
          capturedAt: dt(e['captured_at']),
          latitude: d(e['latitude']),
          longitude: d(e['longitude']),
          reviewStatus: e['review_status'],
          reviewedBy: ni(e['reviewed_by']),
          reviewedAt: dt(e['reviewed_at']),
        );
      }
      return AttendanceRecord(
        attendanceId: n(x['attendance_id']),
        scheduleId: n(x['schedule_id']),
        employeeId: n(x['employee_id']),
        checkInAt: dt(x['check_in_at']),
        checkOutAt: dt(x['check_out_at']),
        checkInLatitude: d(x['check_in_latitude']),
        checkInLongitude: d(x['check_in_longitude']),
        checkOutLatitude: d(x['check_out_latitude']),
        checkOutLongitude: d(x['check_out_longitude']),
        lateMinutes: n(x['late_minutes']),
        attendanceStatus: x['attendance_status'],
        verificationStatus: x['verification_status'],
        verifiedBy: ni(x['verified_by']),
        verifiedAt: dt(x['verified_at']),
        note: x['note'],
        evidence: ev,
      );
    }).toList();
    notifyListeners();
  }

  Future<void> _save(
    String path,
    Map<String, dynamic> body, {
    String method = 'POST',
  }) async {
    await remoteApi!.request(path, method: method, body: body);
    await refresh();
  }

  void _requireBranch() {
    if (_currentBranch.branchId == 0)
      throw StateError(
        'Tài khoản chưa được gán chi nhánh. Nhờ quản trị viên cập nhật trước.',
      );
  }

  void _initData() {
    _employees = [
      Employee(
        employeeId: 1,
        roleId: 2,
        branchId: 1,
        employeeCode: 'MGR001',
        fullName: 'Trần Văn Quản Lý',
        email: 'manager.smq1@supermarket.com',
        phone: '0901 234 567',
        avatarUrl:
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
        employmentStatus: 'ACTIVE',
        hiredDate: DateTime(2023, 1, 15),
      ),
      Employee(
        employeeId: 2,
        roleId: 4,
        branchId: 1,
        employeeCode: 'EMP001',
        fullName: 'Nguyễn Thị Thu Ngân',
        email: 'thungan1@supermarket.com',
        phone: '0912 345 678',
        avatarUrl:
            'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
        employmentStatus: 'ACTIVE',
        hiredDate: DateTime(2023, 3, 1),
      ),
      Employee(
        employeeId: 3,
        roleId: 4,
        branchId: 1,
        employeeCode: 'EMP002',
        fullName: 'Lê Hoàng Kho',
        email: 'kho.le@supermarket.com',
        phone: '0923 456 789',
        avatarUrl:
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
        employmentStatus: 'ACTIVE',
        hiredDate: DateTime(2023, 4, 10),
      ),
      Employee(
        employeeId: 4,
        roleId: 4,
        branchId: 1,
        employeeCode: 'EMP003',
        fullName: 'Phạm Minh Rau Quả',
        email: 'minh.pham@supermarket.com',
        phone: '0934 567 890',
        avatarUrl:
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
        employmentStatus: 'ACTIVE',
        hiredDate: DateTime(2023, 5, 12),
      ),
      Employee(
        employeeId: 5,
        roleId: 4,
        branchId: 1,
        employeeCode: 'EMP004',
        fullName: 'Hoàng Anh Bảo Vệ',
        email: 'bao.ve@supermarket.com',
        phone: '0945 678 901',
        avatarUrl:
            'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150',
        employmentStatus: 'ACTIVE',
        hiredDate: DateTime(2023, 6, 20),
      ),
      Employee(
        employeeId: 6,
        roleId: 4,
        branchId: 1,
        employeeCode: 'EMP005',
        fullName: 'Đỗ Mỹ Linh Bách Hóa',
        email: 'linh.do@supermarket.com',
        phone: '0956 789 012',
        avatarUrl:
            'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?w=150',
        employmentStatus: 'ACTIVE',
        hiredDate: DateTime(2023, 7, 1),
      ),
      Employee(
        employeeId: 7,
        roleId: 4,
        branchId: 1,
        employeeCode: 'EMP006',
        fullName: 'Vũ Quốc Tuấn Thu Ngân',
        email: 'tuan.vu@supermarket.com',
        phone: '0967 890 123',
        avatarUrl:
            'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=150',
        employmentStatus: 'ACTIVE',
        hiredDate: DateTime(2023, 8, 15),
      ),
      Employee(
        employeeId: 8,
        roleId: 4,
        branchId: 1,
        employeeCode: 'EMP007',
        fullName: 'Ngô Thanh Hằng Dịch Vụ',
        email: 'hang.ngo@supermarket.com',
        phone: '0978 901 234',
        avatarUrl:
            'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
        employmentStatus: 'ACTIVE',
        hiredDate: DateTime(2023, 9, 5),
      ),
      Employee(
        employeeId: 9,
        roleId: 4,
        branchId: 1,
        employeeCode: 'EMP008',
        fullName: 'Bùi Gia Huy Kho',
        email: 'huy.bui@supermarket.com',
        phone: '0989 012 345',
        avatarUrl:
            'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=150',
        employmentStatus: 'SUSPENDED',
        hiredDate: DateTime(2023, 10, 1),
      ),
      Employee(
        employeeId: 10,
        roleId: 3,
        branchId: 1,
        employeeCode: 'HR001',
        fullName: 'Đặng Thảo Vy Nhân Sự',
        email: 'vy.hr@supermarket.com',
        phone: '0990 123 456',
        avatarUrl:
            'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150',
        employmentStatus: 'ACTIVE',
        hiredDate: DateTime(2023, 2, 10),
      ),
    ];

    _currentFloorPlan = FloorPlan(
      floorPlanId: 1,
      branchId: 1,
      floorNumber: 1,
      floorName: 'Tầng 1 - Mặt bằng Vận hành Siêu thị',
      imageUrl: 'assets/maps/floor_1.png',
      imageWidth: 1200,
      imageHeight: 800,
    );

    _workAreas = [
      WorkArea(
        workAreaId: 1,
        floorPlanId: 1,
        areaCode: 'CASHIER_01',
        areaName: 'Dãy Quầy Thu Ngân',
        areaType: 'CASHIER',
        maxEmployees: 4,
        mapX: 20.0,
        mapY: 72.0,
        mapWidth: 38.0,
        mapHeight: 18.0,
        radiusMeters: 25,
      ),
      WorkArea(
        workAreaId: 2,
        floorPlanId: 1,
        areaCode: 'FRESH_01',
        areaName: 'Thực Phẩm & Rau Quả',
        areaType: 'FRESH_FOOD',
        maxEmployees: 3,
        mapX: 10.0,
        mapY: 15.0,
        mapWidth: 35.0,
        mapHeight: 45.0,
        radiusMeters: 30,
      ),
      WorkArea(
        workAreaId: 3,
        floorPlanId: 1,
        areaCode: 'GROCERY_01',
        areaName: 'Bách Hóa Tổng Hợp',
        areaType: 'GROCERY',
        maxEmployees: 5,
        mapX: 52.0,
        mapY: 15.0,
        mapWidth: 42.0,
        mapHeight: 40.0,
        radiusMeters: 35,
      ),
      WorkArea(
        workAreaId: 4,
        floorPlanId: 1,
        areaCode: 'WAREHOUSE_01',
        areaName: 'Kho Hàng & Nhập Xuất',
        areaType: 'WAREHOUSE',
        maxEmployees: 4,
        mapX: 62.0,
        mapY: 62.0,
        mapWidth: 32.0,
        mapHeight: 30.0,
        radiusMeters: 40,
      ),
      WorkArea(
        workAreaId: 5,
        floorPlanId: 1,
        areaCode: 'SECURITY_01',
        areaName: 'Trạm An Ninh & Giữ Xe',
        areaType: 'SECURITY',
        maxEmployees: 2,
        mapX: 5.0,
        mapY: 72.0,
        mapWidth: 12.0,
        mapHeight: 18.0,
        radiusMeters: 20,
      ),
      WorkArea(
        workAreaId: 6,
        floorPlanId: 1,
        areaCode: 'CS_01',
        areaName: 'Dịch Vụ Khách Hàng',
        areaType: 'CUSTOMER_SERVICE',
        maxEmployees: 2,
        mapX: 5.0,
        mapY: 40.0,
        mapWidth: 12.0,
        mapHeight: 22.0,
        radiusMeters: 20,
      ),
    ];

    _shifts = [
      Shift(
        shiftId: 1,
        branchId: 1,
        shiftCode: 'CA_SANG',
        shiftName: 'Ca Sáng (06:00 - 14:00)',
        startTime: '06:00:00',
        endTime: '14:00:00',
        checkInEarlyMinutes: 30,
        allowedLateMinutes: 15,
        requireQr: true,
        requireEvidence: true,
        requireLocation: true,
      ),
      Shift(
        shiftId: 2,
        branchId: 1,
        shiftCode: 'CA_CHIEU',
        shiftName: 'Ca Chiều (14:00 - 22:00)',
        startTime: '14:00:00',
        endTime: '22:00:00',
        checkInEarlyMinutes: 30,
        allowedLateMinutes: 15,
        requireQr: true,
        requireEvidence: true,
        requireLocation: true,
      ),
      Shift(
        shiftId: 3,
        branchId: 1,
        shiftCode: 'CA_DEM',
        shiftName: 'Ca Đêm Kiểm Kê (22:00 - 06:00)',
        startTime: '22:00:00',
        endTime: '06:00:00',
        checkInEarlyMinutes: 20,
        allowedLateMinutes: 10,
        requireQr: true,
        requireEvidence: false,
        requireLocation: true,
      ),
    ];

    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    _workSchedules = [
      WorkSchedule(
        scheduleId: 1,
        employeeId: 2, // Thu Ngân
        shiftId: 1, // Ca Sáng
        workAreaId: 1, // Quầy Thu Ngân
        workDate: todayDate,
        scheduleStatus: 'SCHEDULED',
      ),
      WorkSchedule(
        scheduleId: 2,
        employeeId: 7, // Tuấn Thu Ngân
        shiftId: 1, // Ca Sáng
        workAreaId: 1, // Quầy Thu Ngân
        workDate: todayDate,
        scheduleStatus: 'SCHEDULED',
      ),
      WorkSchedule(
        scheduleId: 3,
        employeeId: 3, // Kho
        shiftId: 1, // Ca Sáng
        workAreaId: 4, // Kho
        workDate: todayDate,
        scheduleStatus: 'SCHEDULED',
      ),
      WorkSchedule(
        scheduleId: 4,
        employeeId: 4, // Rau Quả
        shiftId: 1, // Ca Sáng
        workAreaId: 2, // Rau Quả
        workDate: todayDate,
        scheduleStatus: 'SCHEDULED',
      ),
      WorkSchedule(
        scheduleId: 5,
        employeeId: 5, // Bảo Vệ
        shiftId: 1, // Ca Sáng
        workAreaId: 5, // An Ninh
        workDate: todayDate,
        scheduleStatus: 'SCHEDULED',
      ),
      WorkSchedule(
        scheduleId: 6,
        employeeId: 6, // Bách Hóa
        shiftId: 1, // Ca Sáng
        workAreaId: 3, // Bách Hóa
        workDate: todayDate,
        scheduleStatus: 'SCHEDULED',
      ),
      WorkSchedule(
        scheduleId: 7,
        employeeId: 8, // Dịch Vụ
        shiftId: 2, // Ca Chiều
        workAreaId: 6, // Dịch vụ KH
        workDate: todayDate,
        scheduleStatus: 'SCHEDULED',
      ),
    ];

    _attendanceRecords = [
      // Check-in đúng giờ, đã check-out, có ảnh và GPS chi tiết
      AttendanceRecord(
        attendanceId: 1,
        scheduleId: 1,
        employeeId: 2,
        checkInAt: DateTime(today.year, today.month, today.day, 5, 50),
        checkOutAt: DateTime(today.year, today.month, today.day, 14, 05),
        checkInLatitude: 10.77451,
        checkInLongitude: 106.70281,
        checkInAccuracyMeters: 3.5,
        checkOutLatitude: 10.77452,
        checkOutLongitude: 106.70282,
        checkOutAccuracyMeters: 4.1,
        qrSessionCode: 'QR_SMQ1_00192',
        attendanceStatus: 'PRESENT',
        verificationStatus: 'VERIFIED',
        evidence: AttendanceEvidence(
          evidenceId: 1,
          attendanceId: 1,
          evidenceType: 'CHECK_IN_PHOTO',
          fileUrl:
              'https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=500',
          fileHash:
              'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
          capturedAt: DateTime(today.year, today.month, today.day, 5, 50),
          reviewStatus: 'APPROVED',
        ),
      ),
      // Check-in Đi muộn (6:35), Đang chờ duyệt, lateMinutes = 20
      AttendanceRecord(
        attendanceId: 2,
        scheduleId: 2,
        employeeId: 7,
        checkInAt: DateTime(today.year, today.month, today.day, 6, 35),
        checkInLatitude: 10.77452,
        checkInLongitude: 106.70280,
        checkInAccuracyMeters: 4.8,
        qrSessionCode: 'QR_SMQ1_00284',
        lateMinutes: 20,
        attendanceStatus: 'LATE',
        verificationStatus: 'PENDING',
        note: 'Trễ xe buýt 20 phút do tắc đường',
        evidence: AttendanceEvidence(
          evidenceId: 2,
          attendanceId: 2,
          evidenceType: 'CHECK_IN_PHOTO',
          fileUrl:
              'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=500',
          fileHash:
              'ca978112ca1bbdcafac231b39a23dc4da786eff8147c4e72b9807785afee48bb',
          capturedAt: DateTime(today.year, today.month, today.day, 6, 35),
          reviewStatus: 'PENDING',
        ),
      ),
      // Check-in sai vị trí (bán kính ngoài 50m) -> Đang chờ duyệt
      AttendanceRecord(
        attendanceId: 3,
        scheduleId: 3,
        employeeId: 3,
        checkInAt: DateTime(today.year, today.month, today.day, 6, 05),
        checkInLatitude: 10.77600, // Cách 150m
        checkInLongitude: 106.70400,
        checkInAccuracyMeters: 18.2,
        qrSessionCode: 'QR_SMQ1_00319',
        attendanceStatus: 'INVALID_LOCATION',
        verificationStatus: 'PENDING',
        note: 'Bãi đỗ xe đối diện siêu thị, GPS bị trôi tín hiệu',
        evidence: AttendanceEvidence(
          evidenceId: 3,
          attendanceId: 3,
          evidenceType: 'CHECK_IN_PHOTO',
          fileUrl:
              'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=500',
          fileHash:
              '4b227777d4dd1fc61c6f884f48641d02b4d121d3fd328cb08b5531fcacdabf8a',
          capturedAt: DateTime(today.year, today.month, today.day, 6, 05),
          reviewStatus: 'PENDING',
        ),
      ),
      // Đúng giờ, đã check-out
      AttendanceRecord(
        attendanceId: 4,
        scheduleId: 4,
        employeeId: 4,
        checkInAt: DateTime(today.year, today.month, today.day, 5, 55),
        checkOutAt: DateTime(today.year, today.month, today.day, 13, 58),
        checkInLatitude: 10.77453,
        checkInLongitude: 106.70281,
        checkInAccuracyMeters: 2.9,
        checkOutLatitude: 10.77453,
        checkOutLongitude: 106.70282,
        checkOutAccuracyMeters: 3.2,
        qrSessionCode: 'QR_SMQ1_00451',
        attendanceStatus: 'PRESENT',
        verificationStatus: 'VERIFIED',
      ),
      // Đúng giờ, đang làm
      AttendanceRecord(
        attendanceId: 5,
        scheduleId: 5,
        employeeId: 5,
        checkInAt: DateTime(today.year, today.month, today.day, 5, 45),
        checkInLatitude: 10.77450,
        checkInLongitude: 106.70280,
        checkInAccuracyMeters: 3.1,
        qrSessionCode: 'QR_SMQ1_00523',
        attendanceStatus: 'PRESENT',
        verificationStatus: 'VERIFIED',
      ),
    ];
  }

  // Getters
  List<Role> get roles => _roles;
  Branch get currentBranch => _currentBranch;
  List<Employee> get employees => _employees;
  FloorPlan get currentFloorPlan => _currentFloorPlan;
  List<WorkArea> get workAreas => _workAreas;
  List<Shift> get shifts => _shifts;
  List<WorkSchedule> get workSchedules => _workSchedules;
  List<AttendanceRecord> get attendanceRecords => _attendanceRecords;

  // --- EMPLOYEE CRUD ---
  Future<void> addEmployee(Employee emp) async {
    if (isRemote) {
      _requireBranch();
      await _save('/management/employees', {
        'roleId': emp.roleId,
        'branchId': emp.branchId ?? _currentBranch.branchId,
        'employeeCode': emp.employeeCode,
        'fullName': emp.fullName,
        'email': emp.email,
        'phone': emp.phone,
      });
      return;
    }
    final newId =
        (_employees.map((e) => e.employeeId).reduce((a, b) => a > b ? a : b)) +
        1;
    final newEmp = Employee(
      employeeId: newId,
      roleId: emp.roleId,
      branchId: emp.branchId ?? _currentBranch.branchId,
      employeeCode: emp.employeeCode.toUpperCase(),
      fullName: emp.fullName,
      email: emp.email,
      phone: emp.phone,
      avatarUrl:
          emp.avatarUrl ??
          'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
      employmentStatus: emp.employmentStatus,
      hiredDate: emp.hiredDate ?? DateTime.now(),
    );
    _employees.add(newEmp);
    notifyListeners();
  }

  Future<void> updateEmployee(Employee updatedEmp) async {
    if (isRemote) {
      await _save('/management/employees/${updatedEmp.employeeId}', {
        'roleId': updatedEmp.roleId,
        'branchId': updatedEmp.branchId,
        'employeeCode': updatedEmp.employeeCode,
        'fullName': updatedEmp.fullName,
        'email': updatedEmp.email,
        'phone': updatedEmp.phone,
      }, method: 'PUT');
      return;
    }
    final idx = _employees.indexWhere(
      (e) => e.employeeId == updatedEmp.employeeId,
    );
    if (idx != -1) {
      _employees[idx] = updatedEmp;
      notifyListeners();
    }
  }

  Future<void> toggleEmployeeStatus(int employeeId) async {
    if (isRemote) {
      final emp = _employees.firstWhere((e) => e.employeeId == employeeId);
      await _save('/management/employees/$employeeId/status', {
        'status': emp.isActive ? 'SUSPENDED' : 'ACTIVE',
      }, method: 'PATCH');
      return;
    }
    final idx = _employees.indexWhere((e) => e.employeeId == employeeId);
    if (idx != -1) {
      final current = _employees[idx];
      final newStatus = current.employmentStatus == 'ACTIVE'
          ? 'SUSPENDED'
          : 'ACTIVE';
      _employees[idx] = current.copyWith(employmentStatus: newStatus);
      notifyListeners();
    }
  }

  // --- SHIFT CRUD ---
  Future<void> addShift(Shift shift) async {
    if (isRemote) {
      _requireBranch();
      await _save('/management/shifts', {
        'branchId': _currentBranch.branchId,
        'shiftCode': shift.shiftCode,
        'shiftName': shift.shiftName,
        'startTime': shift.startTime,
        'endTime': shift.endTime,
        'requireQr': shift.requireQr,
        'requireEvidence': shift.requireEvidence,
        'requireLocation': shift.requireLocation,
        'allowedLateMinutes': shift.allowedLateMinutes,
      });
      return;
    }
    final newId =
        (_shifts.map((s) => s.shiftId).reduce((a, b) => a > b ? a : b)) + 1;
    _shifts.add(
      Shift(
        shiftId: newId,
        branchId: _currentBranch.branchId,
        shiftCode: shift.shiftCode.toUpperCase(),
        shiftName: shift.shiftName,
        startTime: shift.startTime,
        endTime: shift.endTime,
        checkInEarlyMinutes: shift.checkInEarlyMinutes,
        allowedLateMinutes: shift.allowedLateMinutes,
        allowedEarlyCheckoutMinutes: shift.allowedEarlyCheckoutMinutes,
        requireQr: shift.requireQr,
        requireEvidence: shift.requireEvidence,
        requireLocation: shift.requireLocation,
        isActive: true,
      ),
    );
    notifyListeners();
  }

  Future<void> updateShift(Shift updatedShift) async {
    if (isRemote) {
      throw UnsupportedError('Chỉnh sửa ca làm chưa được backend hỗ trợ.');
    }
    final idx = _shifts.indexWhere((s) => s.shiftId == updatedShift.shiftId);
    if (idx != -1) {
      _shifts[idx] = updatedShift;
      notifyListeners();
    }
  }

  Future<void> toggleShiftActive(int shiftId) async {
    if (isRemote) {
      final shift = _shifts.firstWhere((s) => s.shiftId == shiftId);
      await _save('/management/team-shifts/$shiftId/status', {
        'active': !shift.isActive,
      }, method: 'PATCH');
      return;
    }
    final idx = _shifts.indexWhere((s) => s.shiftId == shiftId);
    if (idx != -1) {
      final current = _shifts[idx];
      _shifts[idx] = current.copyWith(isActive: !current.isActive);
      notifyListeners();
    }
  }

  // --- SCHEDULE ASSIGNMENT (WITH BUSINESS RULES) ---
  Future<(bool success, String message)> assignSchedule({
    required int employeeId,
    required int shiftId,
    required int workAreaId,
    required DateTime date,
    String? note,
  }) async {
    if (isRemote) {
      try {
        await _save('/management/schedules', {
          'employeeId': employeeId,
          'shiftId': shiftId,
          'workAreaId': workAreaId,
          'workDate': TeamApi.day(date),
          'note': note,
        });
        return (true, 'Phân công ca làm thành công!');
      } catch (e) {
        return (false, e.toString());
      }
    }
    final dateOnly = DateTime(date.year, date.month, date.day);

    // Rule 1: Nhân viên không được phân công 2 ca trùng ngày
    final hasConflict = _workSchedules.any(
      (s) =>
          s.employeeId == employeeId &&
          s.workDate.year == dateOnly.year &&
          s.workDate.month == dateOnly.month &&
          s.workDate.day == dateOnly.day,
    );

    if (hasConflict) {
      final emp = _employees.firstWhere((e) => e.employeeId == employeeId);
      return (
        false,
        'Nhân viên ${emp.fullName} đã được xếp lịch làm việc trong ngày này!',
      );
    }

    // Rule 2: Kiểm tra số lượng tối đa trong khu vực (max_employees)
    final area = _workAreas.firstWhere((a) => a.workAreaId == workAreaId);
    if (area.maxEmployees != null) {
      final currentCountInArea = _workSchedules
          .where(
            (s) =>
                s.workAreaId == workAreaId &&
                s.shiftId == shiftId &&
                s.workDate.year == dateOnly.year &&
                s.workDate.month == dateOnly.month &&
                s.workDate.day == dateOnly.day,
          )
          .length;

      if (currentCountInArea >= area.maxEmployees!) {
        return (
          false,
          'Khu vực "${area.areaName}" đã đạt tối đa ${area.maxEmployees} nhân viên trong ca này!',
        );
      }
    }

    final newId =
        (_workSchedules
            .map((s) => s.scheduleId)
            .fold<int>(0, (a, b) => a > b ? a : b)) +
        1;
    _workSchedules.add(
      WorkSchedule(
        scheduleId: newId,
        employeeId: employeeId,
        shiftId: shiftId,
        workAreaId: workAreaId,
        workDate: dateOnly,
        scheduleStatus: 'SCHEDULED',
        note: note,
      ),
    );

    notifyListeners();
    return (true, 'Phân công ca làm thành công!');
  }

  // --- ATTENDANCE APPROVAL ---
  Future<void> approveAttendance(int attendanceId, {String? note}) async {
    if (isRemote) {
      await _save('/management/team-attendance/$attendanceId/review', {
        'decision': 'APPROVED',
        'note': note,
      });
      return;
    }
    final idx = _attendanceRecords.indexWhere(
      (r) => r.attendanceId == attendanceId,
    );
    if (idx != -1) {
      final current = _attendanceRecords[idx];
      AttendanceEvidence? updatedEvidence;
      if (current.evidence != null) {
        updatedEvidence = current.evidence!.copyWith(
          reviewStatus: 'APPROVED',
          reviewedBy: 1, // Manager ID
          reviewedAt: DateTime.now(),
        );
      }

      _attendanceRecords[idx] = current.copyWith(
        attendanceStatus: 'PRESENT',
        verificationStatus: 'VERIFIED',
        verifiedBy: 1,
        verifiedAt: DateTime.now(),
        note: note ?? 'Quản lý đã phê duyệt ngoại lệ hợp lệ',
        evidence: updatedEvidence,
      );
      notifyListeners();
    }
  }

  Future<void> rejectAttendance(
    int attendanceId, {
    required String reason,
  }) async {
    if (isRemote) {
      await _save('/management/team-attendance/$attendanceId/review', {
        'decision': 'REJECTED',
        'note': reason,
      });
      return;
    }
    final idx = _attendanceRecords.indexWhere(
      (r) => r.attendanceId == attendanceId,
    );
    if (idx != -1) {
      final current = _attendanceRecords[idx];
      AttendanceEvidence? updatedEvidence;
      if (current.evidence != null) {
        updatedEvidence = current.evidence!.copyWith(
          reviewStatus: 'REJECTED',
          reviewedBy: 1,
          reviewedAt: DateTime.now(),
        );
      }

      _attendanceRecords[idx] = current.copyWith(
        attendanceStatus: 'REJECTED',
        verificationStatus: 'REJECTED',
        verifiedBy: 1,
        verifiedAt: DateTime.now(),
        note: 'Từ chối: $reason',
        evidence: updatedEvidence,
      );
      notifyListeners();
    }
  }

  // --- FLOOR PLAN & AREA QUERIES ---
  List<Employee> getEmployeesAssignedToArea(int workAreaId, {DateTime? date}) {
    final checkDate = date ?? DateTime.now();
    final scheduleEmpIds = _workSchedules
        .where(
          (s) =>
              s.workAreaId == workAreaId &&
              s.workDate.year == checkDate.year &&
              s.workDate.month == checkDate.month &&
              s.workDate.day == checkDate.day,
        )
        .map((s) => s.employeeId)
        .toSet();

    return _employees
        .where((e) => scheduleEmpIds.contains(e.employeeId))
        .toList();
  }

  String getEmployeeAttendanceStatus(int employeeId, {DateTime? date}) {
    final checkDate = date ?? DateTime.now();
    // Check if scheduled
    final schedule = _workSchedules
        .where(
          (s) =>
              s.employeeId == employeeId &&
              s.workDate.year == checkDate.year &&
              s.workDate.month == checkDate.month &&
              s.workDate.day == checkDate.day,
        )
        .firstOrNull;

    if (schedule == null) return 'NOT_SCHEDULED';

    final record = _attendanceRecords
        .where((r) => r.scheduleId == schedule.scheduleId)
        .firstOrNull;
    if (record == null) return 'ABSENT_OR_PENDING';
    return record.attendanceStatus; // PRESENT, LATE, INVALID_LOCATION, REJECTED
  }

  // --- DASHBOARD & METRICS ---
  int get totalEmployeesCount => _employees.length;
  int get activeEmployeesCount => _employees.where((e) => e.isActive).length;

  int get todayScheduledCount {
    final today = DateTime.now();
    return _workSchedules
        .where(
          (s) =>
              s.workDate.year == today.year &&
              s.workDate.month == today.month &&
              s.workDate.day == today.day,
        )
        .length;
  }

  int get todayPresentCount {
    final today = DateTime.now();
    return _attendanceRecords
        .where(
          (r) =>
              r.checkInAt != null &&
              r.checkInAt!.year == today.year &&
              r.checkInAt!.month == today.month &&
              r.checkInAt!.day == today.day &&
              (r.attendanceStatus == 'PRESENT' ||
                  r.verificationStatus == 'VERIFIED'),
        )
        .length;
  }

  int get todayLateCount {
    final today = DateTime.now();
    return _attendanceRecords
        .where(
          (r) =>
              r.checkInAt != null &&
              r.checkInAt!.year == today.year &&
              r.checkInAt!.month == today.month &&
              r.checkInAt!.day == today.day &&
              r.attendanceStatus == 'LATE',
        )
        .length;
  }

  int get todayInvalidLocationCount {
    return _attendanceRecords
        .where(
          (r) =>
              r.attendanceStatus == 'INVALID_LOCATION' &&
              r.verificationStatus == 'PENDING',
        )
        .length;
  }

  int get pendingApprovalCount {
    return _attendanceRecords
        .where((r) => r.verificationStatus == 'PENDING')
        .length;
  }

  Employee? getEmployeeById(int id) {
    try {
      return _employees.firstWhere((e) => e.employeeId == id);
    } catch (_) {
      return null;
    }
  }

  WorkArea? getWorkAreaById(int id) {
    try {
      return _workAreas.firstWhere((a) => a.workAreaId == id);
    } catch (_) {
      return null;
    }
  }

  Shift? getShiftById(int id) {
    try {
      return _shifts.firstWhere((s) => s.shiftId == id);
    } catch (_) {
      return null;
    }
  }

  // --- THỐNG KÊ BÁO CÁO CHUYÊN SÂU (THÀNH VIÊN 4) ---
  int get todayCheckedInCount {
    final today = DateTime.now();
    return _attendanceRecords
        .where(
          (r) =>
              r.checkInAt != null &&
              r.checkInAt!.year == today.year &&
              r.checkInAt!.month == today.month &&
              r.checkInAt!.day == today.day,
        )
        .length;
  }

  int get todayCheckedOutCount {
    final today = DateTime.now();
    return _attendanceRecords
        .where(
          (r) =>
              r.checkOutAt != null &&
              r.checkOutAt!.year == today.year &&
              r.checkOutAt!.month == today.month &&
              r.checkOutAt!.day == today.day,
        )
        .length;
  }

  int get todayNotCheckedInCount {
    final scheduled = todayScheduledCount;
    final checkedIn = todayCheckedInCount;
    return (scheduled - checkedIn).clamp(0, scheduled);
  }

  // Danh sách nhân viên đi muộn (Màn 3)
  List<Map<String, dynamic>> getLateEmployeesReport() {
    final list = <Map<String, dynamic>>[];
    for (final rec in _attendanceRecords) {
      if (rec.attendanceStatus == 'LATE' || rec.lateMinutes > 0) {
        final emp = getEmployeeById(rec.employeeId);
        final schedule = _workSchedules.firstWhere(
          (s) => s.scheduleId == rec.scheduleId,
          orElse: () => WorkSchedule(
            scheduleId: 0,
            employeeId: rec.employeeId,
            shiftId: 1,
            workAreaId: 1,
            workDate: DateTime.now(),
          ),
        );
        final shift = getShiftById(schedule.shiftId);
        final area = getWorkAreaById(schedule.workAreaId);

        list.add({
          'record': rec,
          'employee': emp,
          'shift': shift,
          'area': area,
          'lateMinutes': rec.lateMinutes > 0 ? rec.lateMinutes : 20,
          'note': rec.note ?? 'Đi muộn hơn quy định ca',
        });
      }
    }
    return list;
  }

  // Danh sách nhân viên có lịch nhưng chưa check-in (Màn 3)
  List<Map<String, dynamic>> getAbsentEmployeesReport() {
    final today = DateTime.now();
    final todaySchedules = _workSchedules
        .where(
          (s) =>
              s.workDate.year == today.year &&
              s.workDate.month == today.month &&
              s.workDate.day == today.day,
        )
        .toList();

    final checkedInScheduleIds = _attendanceRecords
        .where((r) => r.checkInAt != null)
        .map((r) => r.scheduleId)
        .toSet();

    final list = <Map<String, dynamic>>[];
    for (final s in todaySchedules) {
      if (!checkedInScheduleIds.contains(s.scheduleId)) {
        final emp = getEmployeeById(s.employeeId);
        final shift = getShiftById(s.shiftId);
        final area = getWorkAreaById(s.workAreaId);
        list.add({
          'schedule': s,
          'employee': emp,
          'shift': shift,
          'area': area,
          'status': 'CHƯA_CHECK_IN',
        });
      }
    }
    return list;
  }

  // Bảng xếp hạng số lần đi muộn theo nhân viên (Màn 3)
  List<Map<String, dynamic>> getLateLeaderboard() {
    final Map<int, int> countMap = {};
    final Map<int, int> totalMinutesMap = {};

    for (final rec in _attendanceRecords) {
      if (rec.attendanceStatus == 'LATE' || rec.lateMinutes > 0) {
        countMap[rec.employeeId] = (countMap[rec.employeeId] ?? 0) + 1;
        totalMinutesMap[rec.employeeId] =
            (totalMinutesMap[rec.employeeId] ?? 0) +
            (rec.lateMinutes > 0 ? rec.lateMinutes : 20);
      }
    }

    if (countMap.isEmpty) {
      countMap[7] = 3;
      totalMinutesMap[7] = 55;
      countMap[3] = 1;
      totalMinutesMap[3] = 15;
    }

    final list = <Map<String, dynamic>>[];
    countMap.forEach((empId, count) {
      final emp = getEmployeeById(empId);
      list.add({
        'employee': emp,
        'lateCount': count,
        'totalMinutes': totalMinutesMap[empId] ?? 0,
      });
    });

    list.sort(
      (a, b) => (b['lateCount'] as int).compareTo(a['lateCount'] as int),
    );
    return list;
  }

  // Lọc lịch sử chấm công chi tiết theo bộ lọc (Màn 2 & Màn 4)
  List<Map<String, dynamic>> filterDetailedRecords({
    int? employeeId,
    DateTimeRange? dateRange,
    int? shiftId,
    int? workAreaId,
    String? statusFilter,
  }) {
    final list = <Map<String, dynamic>>[];

    for (final schedule in _workSchedules) {
      if (employeeId != null && schedule.employeeId != employeeId) continue;

      if (dateRange != null) {
        if (schedule.workDate.isBefore(dateRange.start) ||
            schedule.workDate.isAfter(
              dateRange.end.add(const Duration(days: 1)),
            )) {
          continue;
        }
      }

      if (shiftId != null && schedule.shiftId != shiftId) continue;
      if (workAreaId != null && schedule.workAreaId != workAreaId) continue;

      final emp = getEmployeeById(schedule.employeeId);
      final shift = getShiftById(schedule.shiftId);
      final area = getWorkAreaById(schedule.workAreaId);
      final record = _attendanceRecords
          .where((r) => r.scheduleId == schedule.scheduleId)
          .firstOrNull;

      if (statusFilter != null && statusFilter != 'ALL') {
        if (statusFilter == 'PRESENT' &&
            (record == null || record.attendanceStatus != 'PRESENT')) {
          continue;
        }
        if (statusFilter == 'LATE' &&
            (record == null || record.attendanceStatus != 'LATE')) {
          continue;
        }
        if (statusFilter == 'NOT_CHECKED_IN' &&
            record != null &&
            record.checkInAt != null) {
          continue;
        }
        if (statusFilter == 'CHECKED_OUT' &&
            (record == null || record.checkOutAt == null)) {
          continue;
        }
      }

      list.add({
        'schedule': schedule,
        'record': record,
        'employee': emp,
        'shift': shift,
        'area': area,
      });
    }

    return list;
  }
}
