import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models/models.dart';
import '../../../services/mock_data_service.dart';
import '../widgets/role_guard_wrapper.dart';

/// MÀN 3: Màn hình báo cáo đi muộn / vắng mặt
/// Ai dùng: ADMIN, MANAGER, HR
class LateAbsentReportScreen extends StatefulWidget {
  const LateAbsentReportScreen({super.key});

  @override
  State<LateAbsentReportScreen> createState() => _LateAbsentReportScreenState();
}

class _LateAbsentReportScreenState extends State<LateAbsentReportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RoleGuardWrapper(
      allowedRoles: const ['ADMIN', 'MANAGER', 'HR'],
      screenTitle: 'Báo cáo đi muộn / vắng mặt',
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(
            '3. Báo cáo đi muộn & Vắng mặt',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(text: 'Đi muộn hôm nay'),
              Tab(text: 'Có lịch chưa vào'),
              Tab(text: 'BXH Số lần trễ'),
            ],
          ),
        ),
        body: Consumer<MockDataService>(
          builder: (context, data, _) {
            final lateList = data.getLateEmployeesReport();
            final absentList = data.getAbsentEmployeesReport();
            final leaderboard = data.getLateLeaderboard();

            return TabBarView(
              controller: _tabController,
              children: [
                // TAB 1: DANH SÁCH NHÂN VIÊN ĐI MUỘN & SỐ PHÚT TRỄ
                _buildLateEmployeesTab(context, lateList),

                // TAB 2: NHÂN VIÊN CÓ LỊCH NHƯNG CHƯA CHECK-IN
                _buildAbsentEmployeesTab(context, absentList),

                // TAB 3: THỐNG KÊ SỐ LẦN ĐI MUỘN THEO TỪNG NHÂN VIÊN
                _buildLeaderboardTab(context, leaderboard),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLateEmployeesTab(
      BuildContext context, List<Map<String, dynamic>> lateList) {
    if (lateList.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.thumb_up_alt_rounded, size: 54, color: Colors.green),
            SizedBox(height: 12),
            Text('Hôm nay không có nhân viên nào đi muộn!',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: lateList.length,
      itemBuilder: (ctx, idx) {
        final item = lateList[idx];
        final emp = item['employee'] as Employee?;
        final shift = item['shift'] as Shift?;
        final area = item['area'] as WorkArea?;
        final record = item['record'] as AttendanceRecord;
        final minutes = item['lateMinutes'] as int;
        final note = item['note'] as String;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFDE68A)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(emp?.avatarUrl ?? ''),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          emp?.fullName ?? 'Chưa rõ',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          '${emp?.employeeCode ?? ""}  •  Khu vực: ${area?.areaName ?? ""}',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFF59E0B)),
                    ),
                    child: Text(
                      '+$minutes phút trễ',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Quy định ca: ${shift?.startTime.substring(0, 5) ?? ""}',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                    Text(
                      'Giờ vào thực tế: ${record.checkInAt != null ? DateFormat("HH:mm:ss").format(record.checkInAt!) : ""}',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.red),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Lý do: "$note"',
                style: const TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAbsentEmployeesTab(
      BuildContext context, List<Map<String, dynamic>> absentList) {
    if (absentList.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded, size: 54, color: Colors.green),
            SizedBox(height: 12),
            Text('Toàn bộ nhân viên có ca đều đã check-in đầy đủ!',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: absentList.length,
      itemBuilder: (ctx, idx) {
        final item = absentList[idx];
        final emp = item['employee'] as Employee?;
        final shift = item['shift'] as Shift?;
        final area = item['area'] as WorkArea?;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(emp?.avatarUrl ?? ''),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      emp?.fullName ?? 'Chưa rõ',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${shift?.shiftName ?? ""} (${shift?.startTime.substring(0, 5)} - ${shift?.endTime.substring(0, 5)})',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                    Text(
                      'Khu vực: ${area?.areaName ?? ""}',
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE4E6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Chưa vào ca',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLeaderboardTab(
      BuildContext context, List<Map<String, dynamic>> leaderboard) {
    return ListView.builder(
      padding: const EdgeInsets.all(14),
      itemCount: leaderboard.length,
      itemBuilder: (ctx, idx) {
        final item = leaderboard[idx];
        final emp = item['employee'] as Employee?;
        final lateCount = item['lateCount'] as int;
        final totalMinutes = item['totalMinutes'] as int;

        Color badgeColor = Colors.grey.shade600;
        if (idx == 0) badgeColor = Colors.amber.shade700;
        if (idx == 1) badgeColor = Colors.blueGrey;
        if (idx == 2) badgeColor = Colors.brown;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '#${idx + 1}',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: badgeColor,
                      fontSize: 12),
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 18,
                backgroundImage: NetworkImage(emp?.avatarUrl ?? ''),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      emp?.fullName ?? 'Chưa rõ',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    Text(
                      '${emp?.employeeCode ?? ""}  •  ${emp?.email ?? ""}',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$lateCount lần vi phạm',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.red),
                  ),
                  Text(
                    'Tổng: $totalMinutes phút',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

