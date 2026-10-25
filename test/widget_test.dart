import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supermarket_hrm/models/models.dart';
import 'package:supermarket_hrm/services/mock_data_service.dart';

void main() async {
  group('Kiểm tra nghiệp vụ Thành viên 4 (SmartMarket HRM):', () {
    late MockDataService dataService;

    setUp(() async {
      dataService = MockDataService();
    });

    test('1. Khởi tạo dữ liệu mẫu siêu thị thành công', () async {
      expect(dataService.employees.length, greaterThanOrEqualTo(10));
      expect(dataService.workAreas.length, equals(6));
      expect(dataService.shifts.length, equals(3));
      expect(dataService.currentBranch.branchCode, equals('SM_Q1'));
    });

    test(
      '2. Business Rule: Không cho phép phân công nhân viên 2 ca trong cùng ngày',
      () async {
        final today = DateTime.now();

        // Nhân viên id=2 đã được xếp ca trong ngày hôm nay
        final (success, message) = await dataService.assignSchedule(
          employeeId: 2,
          shiftId: 2,
          workAreaId: 1,
          date: today,
        );

        expect(success, isFalse);
        expect(message, contains('đã được xếp lịch làm việc'));
      },
    );

    test(
      '3. Business Rule: Không cho phép xếp vượt quá max_employees của khu vực',
      () async {
        final tomorrow = DateTime.now().add(const Duration(days: 1));

        // Khu vực 5 (SECURITY_01) có maxEmployees = 2
        final area = dataService.workAreas.firstWhere((a) => a.workAreaId == 5);
        expect(area.maxEmployees, equals(2));

        // Phân công người thứ 1 -> Thành công
        final res1 = await dataService.assignSchedule(
          employeeId: 5,
          shiftId: 1,
          workAreaId: 5,
          date: tomorrow,
        );
        expect(res1.$1, isTrue);

        // Phân công người thứ 2 -> Thành công
        final res2 = await dataService.assignSchedule(
          employeeId: 6,
          shiftId: 1,
          workAreaId: 5,
          date: tomorrow,
        );
        expect(res2.$1, isTrue);

        // Phân công người thứ 3 -> Bị chặn vì quá tải
        final res3 = await dataService.assignSchedule(
          employeeId: 7,
          shiftId: 1,
          workAreaId: 5,
          date: tomorrow,
        );
        expect(res3.$1, isFalse);
        expect(res3.$2, contains('đã đạt tối đa 2 nhân viên'));
      },
    );

    test('4. Nghiệp vụ: Quản lý phê duyệt chấm công bất thường', () async {
      final pendingCountBefore = dataService.pendingApprovalCount;
      expect(pendingCountBefore, greaterThan(0));

      // Lấy bản ghi cần duyệt
      final pendingRecord = dataService.attendanceRecords.firstWhere(
        (r) => r.verificationStatus == 'PENDING',
      );

      // Quản lý duyệt
      await dataService.approveAttendance(pendingRecord.attendanceId);

      // Kiểm tra trạng thái đã chuyển sang VERIFIED và số lượng pending giảm
      final updatedRecord = dataService.attendanceRecords.firstWhere(
        (r) => r.attendanceId == pendingRecord.attendanceId,
      );
      expect(updatedRecord.verificationStatus, equals('VERIFIED'));
      expect(updatedRecord.attendanceStatus, equals('PRESENT'));
      expect(dataService.pendingApprovalCount, equals(pendingCountBefore - 1));
    });

    test('5. Nghiệp vụ: Khóa và kích hoạt lại tài khoản nhân viên', () async {
      final emp = dataService.employees.firstWhere((e) => e.employeeId == 2);
      expect(emp.employmentStatus, equals('ACTIVE'));

      // Tạm khóa
      await dataService.toggleEmployeeStatus(2);
      expect(
        dataService.employees
            .firstWhere((e) => e.employeeId == 2)
            .employmentStatus,
        equals('SUSPENDED'),
      );

      // Mở khóa lại
      await dataService.toggleEmployeeStatus(2);
      expect(
        dataService.employees
            .firstWhere((e) => e.employeeId == 2)
            .employmentStatus,
        equals('ACTIVE'),
      );
    });

    test('6. Báo cáo 1: Thống kê tổng quan chấm công hôm nay', () async {
      expect(dataService.totalEmployeesCount, greaterThanOrEqualTo(10));
      expect(dataService.todayScheduledCount, greaterThan(0));
      expect(dataService.todayCheckedInCount, greaterThan(0));
      expect(dataService.todayLateCount, greaterThan(0));
      expect(dataService.todayCheckedOutCount, greaterThanOrEqualTo(0));
      expect(dataService.todayNotCheckedInCount, greaterThanOrEqualTo(0));
      // Tổng có mặt + chưa check-in = tổng có lịch
      expect(
        dataService.todayCheckedInCount + dataService.todayNotCheckedInCount,
        equals(dataService.todayScheduledCount),
      );
    });

    test(
      '7. Báo cáo 2: Lọc báo cáo chấm công theo nhân viên, ca, khu vực, trạng thái',
      () async {
        final today = DateTime.now();
        final from = DateTime(today.year, today.month, 1);
        final to = DateTime(today.year, today.month, 28);

        // Lọc toàn bộ
        final allFiltered = dataService.filterDetailedRecords(
          dateRange: DateTimeRange(start: from, end: to),
        );
        expect(allFiltered, isNotEmpty);

        // Lọc theo trạng thái LATE
        final lateOnly = dataService.filterDetailedRecords(
          dateRange: DateTimeRange(start: from, end: to),
          statusFilter: 'LATE',
        );
        expect(
          lateOnly.every(
            (r) =>
                (r['record'] as AttendanceRecord?)?.attendanceStatus == 'LATE',
          ),
          isTrue,
        );

        // Lọc theo ca làm id=1
        final shift1Only = dataService.filterDetailedRecords(
          dateRange: DateTimeRange(start: from, end: to),
          shiftId: 1,
        );
        expect(
          shift1Only.every((r) => (r['schedule'] as WorkSchedule).shiftId == 1),
          isTrue,
        );
      },
    );

    test(
      '8. Báo cáo 3: Danh sách đi muộn, vắng mặt & bảng xếp hạng số lần trễ',
      () async {
        final lateList = dataService.getLateEmployeesReport();
        expect(lateList, isNotEmpty);
        expect(lateList.first['lateMinutes'], greaterThan(0));

        final absentList = dataService.getAbsentEmployeesReport();
        expect(absentList, isList);

        final leaderboard = dataService.getLateLeaderboard();
        expect(leaderboard, isNotEmpty);
        expect(leaderboard.first['lateCount'], greaterThanOrEqualTo(1));
      },
    );

    test(
      '9. Báo cáo 4: Phân quyền xem lịch sử chi tiết (EMPLOYEE vs ADMIN/MANAGER/HR)',
      () async {
        // 1. Vai trò ADMIN/MANAGER/HR: xem được tất cả nhân viên
        dataService.setCurrentRole('MANAGER');
        final adminRecords = dataService.filterDetailedRecords();
        expect(adminRecords.length, greaterThan(1));

        // 2. Vai trò EMPLOYEE: chỉ xem được của chính mình (id=2)
        dataService.setCurrentRole('EMPLOYEE', employeeId: 2);
        final employeeRecords = dataService.filterDetailedRecords(
          employeeId: dataService.currentLoggedInEmployeeId,
        );
        expect(
          employeeRecords.every(
            (r) => (r['schedule'] as WorkSchedule).employeeId == 2,
          ),
          isTrue,
        );

        // Kiểm tra có thông tin GPS, độ chính xác và mã QR
        final recordWithGps = employeeRecords
            .map((r) => r['record'] as AttendanceRecord?)
            .firstWhere((rec) => rec != null && rec.checkInLatitude != null)!;
        expect(recordWithGps.checkInAccuracyMeters, isNotNull);
        expect(recordWithGps.qrSessionCode, isNotNull);
      },
    );

    test(
      '10. Báo cáo 5: Chuyển đổi linh hoạt giữa các vai trò Role Switcher',
      () async {
        dataService.setCurrentRole('ADMIN');
        expect(dataService.currentRoleCode, equals('ADMIN'));

        dataService.setCurrentRole('HR');
        expect(dataService.currentRoleCode, equals('HR'));

        dataService.setCurrentRole('EMPLOYEE');
        expect(dataService.currentRoleCode, equals('EMPLOYEE'));
      },
    );
  });
}
