// Models ánh xạ 1:1 với cơ sở dữ liệu SQL Server smartmarket_hrm

enum RoleCode { admin, manager, hr, employee }

enum EmploymentStatus { active, inactive, suspended }

enum AreaType {
  cashier,
  warehouse,
  freshFood,
  grocery,
  security,
  office,
  customerService,
  other,
}

enum ScheduleStatus { scheduled, cancelled, completed, absent }

enum AttendanceStatus {
  pending,
  present,
  late,
  absent,
  invalidLocation,
  rejected,
}

enum VerificationStatus { pending, verified, rejected }

enum EvidenceType { checkInPhoto, checkOutPhoto, other }

enum ReviewStatus { pending, approved, rejected }

class Role {
  final int roleId;
  final String roleCode;
  final String roleName;
  final String? description;

  Role({
    required this.roleId,
    required this.roleCode,
    required this.roleName,
    this.description,
  });
}

class Branch {
  final int branchId;
  final String branchCode;
  final String branchName;
  final String address;
  final String? phone;
  final double? latitude;
  final double? longitude;
  final bool isActive;

  Branch({
    required this.branchId,
    required this.branchCode,
    required this.branchName,
    required this.address,
    this.phone,
    this.latitude,
    this.longitude,
    this.isActive = true,
  });
}

class Employee {
  final int employeeId;
  final int roleId;
  final int? branchId;
  final String employeeCode;
  final String fullName;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final String? googleSub;
  final String employmentStatus; // 'ACTIVE', 'INACTIVE', 'SUSPENDED'
  final DateTime? hiredDate;

  Employee({
    required this.employeeId,
    required this.roleId,
    this.branchId,
    required this.employeeCode,
    required this.fullName,
    required this.email,
    this.phone,
    this.avatarUrl,
    this.googleSub,
    this.employmentStatus = 'ACTIVE',
    this.hiredDate,
  });

  bool get isActive => employmentStatus == 'ACTIVE';

  Employee copyWith({
    int? roleId,
    int? branchId,
    String? employeeCode,
    String? fullName,
    String? email,
    String? phone,
    String? avatarUrl,
    String? employmentStatus,
    DateTime? hiredDate,
  }) {
    return Employee(
      employeeId: employeeId,
      roleId: roleId ?? this.roleId,
      branchId: branchId ?? this.branchId,
      employeeCode: employeeCode ?? this.employeeCode,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      googleSub: googleSub,
      employmentStatus: employmentStatus ?? this.employmentStatus,
      hiredDate: hiredDate ?? this.hiredDate,
    );
  }
}

class FloorPlan {
  final int floorPlanId;
  final int branchId;
  final int floorNumber;
  final String floorName;
  final String imageUrl;
  final int? imageWidth;
  final int? imageHeight;
  final bool isActive;

  FloorPlan({
    required this.floorPlanId,
    required this.branchId,
    required this.floorNumber,
    required this.floorName,
    required this.imageUrl,
    this.imageWidth,
    this.imageHeight,
    this.isActive = true,
  });
}

class WorkArea {
  final int workAreaId;
  final int floorPlanId;
  final String areaCode;
  final String areaName;
  final String areaType; // CASHIER, WAREHOUSE, FRESH_FOOD, GROCERY, SECURITY, etc.
  final int? maxEmployees;
  final double mapX; // Tọa độ X % (0 - 100)
  final double mapY; // Tọa độ Y % (0 - 100)
  final double? mapWidth;
  final double? mapHeight;
  final double? latitude;
  final double? longitude;
  final int? radiusMeters;
  final bool isActive;

  WorkArea({
    required this.workAreaId,
    required this.floorPlanId,
    required this.areaCode,
    required this.areaName,
    required this.areaType,
    this.maxEmployees,
    required this.mapX,
    required this.mapY,
    this.mapWidth,
    this.mapHeight,
    this.latitude,
    this.longitude,
    this.radiusMeters,
    this.isActive = true,
  });
}

class Shift {
  final int shiftId;
  final int branchId;
  final String shiftCode;
  final String shiftName;
  final String startTime; // '06:00:00'
  final String endTime; // '14:00:00'
  final int checkInEarlyMinutes;
  final int allowedLateMinutes;
  final int allowedEarlyCheckoutMinutes;
  final bool requireQr;
  final bool requireEvidence;
  final bool requireLocation;
  final bool isActive;

  Shift({
    required this.shiftId,
    required this.branchId,
    required this.shiftCode,
    required this.shiftName,
    required this.startTime,
    required this.endTime,
    this.checkInEarlyMinutes = 30,
    this.allowedLateMinutes = 15,
    this.allowedEarlyCheckoutMinutes = 0,
    this.requireQr = true,
    this.requireEvidence = false,
    this.requireLocation = false,
    this.isActive = true,
  });

  Shift copyWith({
    String? shiftCode,
    String? shiftName,
    String? startTime,
    String? endTime,
    int? checkInEarlyMinutes,
    int? allowedLateMinutes,
    int? allowedEarlyCheckoutMinutes,
    bool? requireQr,
    bool? requireEvidence,
    bool? requireLocation,
    bool? isActive,
  }) {
    return Shift(
      shiftId: shiftId,
      branchId: branchId,
      shiftCode: shiftCode ?? this.shiftCode,
      shiftName: shiftName ?? this.shiftName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      checkInEarlyMinutes: checkInEarlyMinutes ?? this.checkInEarlyMinutes,
      allowedLateMinutes: allowedLateMinutes ?? this.allowedLateMinutes,
      allowedEarlyCheckoutMinutes:
          allowedEarlyCheckoutMinutes ?? this.allowedEarlyCheckoutMinutes,
      requireQr: requireQr ?? this.requireQr,
      requireEvidence: requireEvidence ?? this.requireEvidence,
      requireLocation: requireLocation ?? this.requireLocation,
      isActive: isActive ?? this.isActive,
    );
  }
}

class WorkSchedule {
  final int scheduleId;
  final int employeeId;
  final int shiftId;
  final int workAreaId;
  final DateTime workDate;
  final String scheduleStatus; // SCHEDULED, CANCELLED, COMPLETED, ABSENT
  final int? assignedBy;
  final String? note;

  WorkSchedule({
    required this.scheduleId,
    required this.employeeId,
    required this.shiftId,
    required this.workAreaId,
    required this.workDate,
    this.scheduleStatus = 'SCHEDULED',
    this.assignedBy,
    this.note,
  });

  WorkSchedule copyWith({
    int? employeeId,
    int? shiftId,
    int? workAreaId,
    DateTime? workDate,
    String? scheduleStatus,
    int? assignedBy,
    String? note,
  }) {
    return WorkSchedule(
      scheduleId: scheduleId,
      employeeId: employeeId ?? this.employeeId,
      shiftId: shiftId ?? this.shiftId,
      workAreaId: workAreaId ?? this.workAreaId,
      workDate: workDate ?? this.workDate,
      scheduleStatus: scheduleStatus ?? this.scheduleStatus,
      assignedBy: assignedBy ?? this.assignedBy,
      note: note ?? this.note,
    );
  }
}

class AttendanceEvidence {
  final int evidenceId;
  final int attendanceId;
  final String evidenceType; // CHECK_IN_PHOTO, CHECK_OUT_PHOTO, OTHER
  final String fileUrl;
  final String fileHash;
  final DateTime? capturedAt;
  final double? latitude;
  final double? longitude;
  final String? deviceInfo;
  final String reviewStatus; // PENDING, APPROVED, REJECTED
  final int? reviewedBy;
  final DateTime? reviewedAt;

  AttendanceEvidence({
    required this.evidenceId,
    required this.attendanceId,
    required this.evidenceType,
    required this.fileUrl,
    required this.fileHash,
    this.capturedAt,
    this.latitude,
    this.longitude,
    this.deviceInfo,
    this.reviewStatus = 'PENDING',
    this.reviewedBy,
    this.reviewedAt,
  });

  AttendanceEvidence copyWith({
    String? reviewStatus,
    int? reviewedBy,
    DateTime? reviewedAt,
  }) {
    return AttendanceEvidence(
      evidenceId: evidenceId,
      attendanceId: attendanceId,
      evidenceType: evidenceType,
      fileUrl: fileUrl,
      fileHash: fileHash,
      capturedAt: capturedAt,
      latitude: latitude,
      longitude: longitude,
      deviceInfo: deviceInfo,
      reviewStatus: reviewStatus ?? this.reviewStatus,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
    );
  }
}

class AttendanceRecord {
  final int attendanceId;
  final int scheduleId;
  final int employeeId;
  final DateTime? checkInAt;
  final DateTime? checkOutAt;
  final double? checkInLatitude;
  final double? checkInLongitude;
  final double? checkInAccuracyMeters;
  final double? checkOutLatitude;
  final double? checkOutLongitude;
  final double? checkOutAccuracyMeters;
  final String? qrSessionCode;
  final int lateMinutes;
  final String attendanceStatus; // PENDING, PRESENT, LATE, ABSENT, INVALID_LOCATION, REJECTED
  final String verificationStatus; // PENDING, VERIFIED, REJECTED
  final int? verifiedBy;
  final DateTime? verifiedAt;
  final String? note;
  final AttendanceEvidence? evidence;

  AttendanceRecord({
    required this.attendanceId,
    required this.scheduleId,
    required this.employeeId,
    this.checkInAt,
    this.checkOutAt,
    this.checkInLatitude,
    this.checkInLongitude,
    this.checkInAccuracyMeters,
    this.checkOutLatitude,
    this.checkOutLongitude,
    this.checkOutAccuracyMeters,
    this.qrSessionCode,
    this.lateMinutes = 0,
    this.attendanceStatus = 'PENDING',
    this.verificationStatus = 'PENDING',
    this.verifiedBy,
    this.verifiedAt,
    this.note,
    this.evidence,
  });

  AttendanceRecord copyWith({
    DateTime? checkInAt,
    DateTime? checkOutAt,
    double? checkInLatitude,
    double? checkInLongitude,
    double? checkInAccuracyMeters,
    double? checkOutLatitude,
    double? checkOutLongitude,
    double? checkOutAccuracyMeters,
    String? qrSessionCode,
    int? lateMinutes,
    String? attendanceStatus,
    String? verificationStatus,
    int? verifiedBy,
    DateTime? verifiedAt,
    String? note,
    AttendanceEvidence? evidence,
  }) {
    return AttendanceRecord(
      attendanceId: attendanceId,
      scheduleId: scheduleId,
      employeeId: employeeId,
      checkInAt: checkInAt ?? this.checkInAt,
      checkOutAt: checkOutAt ?? this.checkOutAt,
      checkInLatitude: checkInLatitude ?? this.checkInLatitude,
      checkInLongitude: checkInLongitude ?? this.checkInLongitude,
      checkInAccuracyMeters: checkInAccuracyMeters ?? this.checkInAccuracyMeters,
      checkOutLatitude: checkOutLatitude ?? this.checkOutLatitude,
      checkOutLongitude: checkOutLongitude ?? this.checkOutLongitude,
      checkOutAccuracyMeters: checkOutAccuracyMeters ?? this.checkOutAccuracyMeters,
      qrSessionCode: qrSessionCode ?? this.qrSessionCode,
      lateMinutes: lateMinutes ?? this.lateMinutes,
      attendanceStatus: attendanceStatus ?? this.attendanceStatus,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      verifiedBy: verifiedBy ?? this.verifiedBy,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      note: note ?? this.note,
      evidence: evidence ?? this.evidence,
    );
  }
}
