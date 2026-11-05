import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../core/services/device_identity_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_error.dart';
import '../../core/widgets/app_loading.dart';
import '../../core/widgets/app_workspace.dart';
import '../../core/widgets/empty_state.dart';
import '../auth/data/account_auth_api.dart';
import 'location/location_service.dart';
import 'qr_scanner_page.dart';

class EmployeeWorkspace extends StatefulWidget {
  const EmployeeWorkspace({
    super.key,
    required this.employeeId,
    required this.idToken,
    required this.fullName,
    required this.email,
    required this.roleCode,
    required this.roleName,
    required this.onLogout,
    this.branchName,
  });

  final int employeeId;
  final String idToken;
  final String fullName;
  final String email;
  final String roleCode;
  final String roleName;
  final String? branchName;
  final Future<void> Function() onLogout;

  @override
  State<EmployeeWorkspace> createState() => _EmployeeWorkspaceState();
}

class _EmployeeWorkspaceState extends State<EmployeeWorkspace> {
  int _tab = 0;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _schedules = [];
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Map<String, String> get _headers => {
    'Authorization': 'Bearer ${widget.idToken}',
    'X-Device-Id': DeviceIdentityService.currentId,
    'Content-Type': 'application/json',
  };

  String get _base {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return override;
    return accountApiBaseUrl;
  }

  String _dateText(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  String get _today => _dateText(DateTime.now());

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final today = DateTime.now();
      final scheduleUri = Uri.parse(
        '$_base/employees/${widget.employeeId}/schedules',
      ).replace(
        queryParameters: {
          'from': _dateText(today.subtract(const Duration(days: 7))),
          'to': _dateText(today.add(const Duration(days: 30))),
        },
      );
      final results = await Future.wait([
        http.get(scheduleUri, headers: _headers),
        http.get(
          Uri.parse('$_base/attendance/employees/${widget.employeeId}/history'),
          headers: _headers,
        ),
      ]);
      _ensureOk(results[0]);
      _ensureOk(results[1]);
      if (mounted) {
        setState(() {
          _schedules = _asList(results[0].body);
          _history = _asList(results[1].body);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = AppError.friendlyMessage(e));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _attendance(Map<String, dynamic> schedule, bool checkIn) async {
    // Chỉ cho phép quét QR bằng camera ở bản chính thức; không nhập mã thủ công.
    final token = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => QrScannerPage(
          title: checkIn ? 'Quét QR Check-in' : 'Quét QR Check-out',
        ),
      ),
    );
    if (token == null || token.trim().isEmpty) return;
    try {
      // GPS bắt buộc: luôn đo vị trí mới ngay lúc chấm công, không dùng vị trí cũ.
      // GPS tắt / từ chối quyền / sai số lớn / giả lập → GpsException với thông báo tiếng Việt.
      final location = await GpsService.instance.getFreshLocation();
      final response = await http.post(
        Uri.parse('$_base/attendance/${checkIn ? 'check-in' : 'check-out'}'),
        headers: _headers,
        body: jsonEncode({
          'scheduleId': schedule['scheduleId'],
          'employeeId': widget.employeeId,
          'qrToken': token,
          ...location.toJson(),
          'clientTime': isoWithOffset(DateTime.now()),
        }),
      );
      _ensureOk(response);
      if (!mounted) return;
      final data = _asMap(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data['message']?.toString() ?? 'Chấm công thành công.'),
        ),
      );
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_message(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppWorkspace(
      title: 'Dashboard nhân viên',
      selectedIndex: _tab,
      onSelected: (value) => setState(() => _tab = value),
      destinations: const [
        WorkspaceDestination('Tổng quan', Icons.dashboard_outlined),
        WorkspaceDestination('Lịch làm', Icons.calendar_month_outlined),
        WorkspaceDestination('Lịch sử chấm công', Icons.history_rounded),
      ],
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(
            _tab == 0
                ? 'Dashboard nhân viên'
                : _tab == 1
                ? 'Lịch làm việc'
                : 'Lịch sử chấm công',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          elevation: 0,
          actions: [
            IconButton(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Tải lại dữ liệu',
            ),
            IconButton(
              onPressed: widget.onLogout,
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Đăng xuất',
            ),
          ],
        ),
        body: IndexedStack(
                index: _tab,
                children: [_buildOverview(), _buildScheduleTab(), _buildHistoryTab()],
              ),
      ),
    );
  }

  // ==========================================
  // TAB 1: TỔNG QUAN (DASHBOARD NHÂN VIÊN)
  // ==========================================
  Widget _buildOverview() {
    final todaySchedules = _schedules
        .where((s) => s['workDate']?.toString() == _today)
        .toList();

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          // 1. Thẻ thông tin nhân viên, vai trò, chi nhánh
          _buildEmployeeHeaderCard(),
          const SizedBox(height: 20),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: AppLoading(message: 'Đang tải thông tin ca làm việc...'),
            )
          else if (_error != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: AppError(message: _error!, onRetry: _load),
            )
          else ...[

          // 2. Ca làm hôm nay tiêu đề
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ca làm việc hôm nay',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  DateFormat('dd/MM/yyyy').format(DateTime.now()),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // 3. Danh sách ca làm hôm nay hoặc Empty State
          if (todaySchedules.isEmpty)
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.divider),
              ),
              color: Colors.white,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                child: EmptyState(
                  icon: Icons.event_available_outlined,
                  title: 'Hôm nay bạn không có ca làm',
                  message:
                      'Hiện tại chưa có ca làm việc nào được xếp cho bạn trong ngày hôm nay.',
                ),
              ),
            )
          else
            ...todaySchedules.map((s) => _buildScheduleCard(s, isTodaySchedule: true)),

          const SizedBox(height: 24),

          // 4. Lối tắt xem lịch làm sắp tới
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryLight.withValues(alpha: .5),
                  Colors.white,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primaryLight),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.calendar_today_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Xem lịch tuần này',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Tổng cộng ${_schedules.length} ca làm trong 30 ngày tới',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.tonal(
                  onPressed: () => setState(() => _tab = 1),
                  style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Xem lịch'),
                ),
              ],
            ),
          ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmployeeHeaderCard() {
    final initials = widget.fullName.trim().isNotEmpty
        ? widget.fullName.trim().split(' ').last[0].toUpperCase()
        : 'NV';

    final branch = widget.branchName != null && widget.branchName!.isNotEmpty
        ? widget.branchName!
        : 'Siêu thị SmartMarket Center';

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F4C6E), Color(0xFF19799A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.20),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white.withValues(alpha: .18),
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.fullName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.email,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFFD5EDF6),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(height: 1, color: Colors.white.withValues(alpha: .20)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoBadge(
                Icons.badge_outlined,
                widget.roleName.isNotEmpty ? widget.roleName : 'Nhân viên',
                const Color(0xFF0F4C6E),
                Colors.white,
              ),
              _buildInfoBadge(
                Icons.store_outlined,
                branch,
                const Color(0xFF0F4C6E),
                const Color(0xFFDDF6F7),
              ),
              _buildInfoBadge(
                Icons.pin_outlined,
                'ID: #${widget.employeeId}',
                const Color(0xFF0F4C6E),
                const Color(0xFFE7F1F6),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBadge(
    IconData icon,
    String label,
    Color textColor,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: LỊCH LÀM VIỆC (RESPONSIVE PHONES & WEB)
  // ==========================================
  Widget _buildScheduleTab() {
    if (_loading) {
      return const AppLoading(message: 'Đang tải lịch làm việc...');
    }
    if (_error != null) {
      return AppError(message: _error!, onRetry: _load);
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          Row(
            children: [
              const Icon(Icons.date_range_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Lịch làm việc của bạn (${_schedules.length} ca)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Bao gồm các ca trong vòng 7 ngày trước và 30 ngày tới.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          if (_schedules.isEmpty)
            const EmptyState(
              icon: Icons.event_busy_outlined,
              title: 'Không có lịch làm việc',
              message: 'Bạn chưa có ca làm nào trong khoảng thời gian này.',
            )
          else
            ..._schedules.map((s) => _buildScheduleCard(s)),
        ],
      ),
    );
  }

  // ==========================================
  // CARD LỊCH LÀM (GIAO DIỆN CHỈNH CHU CHO MOBILE & WEB)
  // ==========================================
  Widget _buildScheduleCard(
    Map<String, dynamic> s, {
    bool isTodaySchedule = false,
  }) {
    final workDateStr = s['workDate']?.toString() ?? '';
    final isToday = workDateStr == _today;
    final checkedIn = s['checkInAt'] != null;
    final checkedOut = s['checkOutAt'] != null;

    // Phân tích trạng thái ca
    String statusLabel = 'Chưa check-in';
    Color statusBg = const Color(0xFFF3F4F6);
    Color statusColor = AppColors.textSecondary;
    IconData statusIcon = Icons.hourglass_top_rounded;

    if (checkedOut) {
      statusLabel = 'Đã check-out';
      statusBg = const Color(0xFFE8F5E9);
      statusColor = AppColors.secondary;
      statusIcon = Icons.check_circle_rounded;
    } else if (checkedIn) {
      statusLabel = 'Đã check-in';
      statusBg = AppColors.primaryLight;
      statusColor = AppColors.primary;
      statusIcon = Icons.task_alt_rounded;
    } else if (isToday) {
      // Kiểm tra đi muộn nếu quá giờ bắt đầu
      final startTimeStr = s['startTime']?.toString() ?? '';
      if (startTimeStr.isNotEmpty) {
        final now = DateTime.now();
        final parts = startTimeStr.split(':');
        if (parts.length >= 2) {
          final startHour = int.tryParse(parts[0]) ?? 0;
          final startMin = int.tryParse(parts[1]) ?? 0;
          final shiftStartTime = DateTime(now.year, now.month, now.day, startHour, startMin);
          if (now.isAfter(shiftStartTime.add(const Duration(minutes: 5)))) {
            final lateMins = now.difference(shiftStartTime).inMinutes;
            statusLabel = 'Đi muộn +$lateMins phút';
            statusBg = const Color(0xFFFEF3C7);
            statusColor = AppColors.statusLate;
            statusIcon = Icons.warning_amber_rounded;
          }
        }
      }
    }

    DateTime? workDateParsed;
    try {
      workDateParsed = DateTime.parse(workDateStr);
    } catch (_) {}

    final formattedDate = workDateParsed != null
        ? DateFormat('EEEE, dd/MM/yyyy', 'vi').format(workDateParsed)
        : workDateStr;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isToday ? AppColors.primary.withValues(alpha: 0.3) : AppColors.divider,
          width: isToday ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isToday
                ? AppColors.primary.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card: Ngày và Trạng thái
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isToday)
                        Container(
                          margin: const EdgeInsets.only(bottom: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'HÔM NAY',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isToday ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 13, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: 12),

            // Thông tin ca làm: Tên ca, giờ làm, khu vực
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.access_time_filled_rounded,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s['shiftName']?.toString() ?? 'Ca làm việc',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${s['startTime'] ?? '--:--'} - ${s['endTime'] ?? '--:--'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Địa điểm / Quầy
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.store_mall_directory_rounded,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${s['areaName'] ?? 'Chưa phân khu'} · ${s['floorName'] ?? 'Tầng trệt'}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),

            // Thời gian check-in / check-out đã ghi nhận (nếu có)
            if (checkedIn || checkedOut) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Row(
                  children: [
                    if (checkedIn) ...[
                      const Icon(Icons.login_rounded, size: 14, color: AppColors.secondary),
                      const SizedBox(width: 4),
                      Text(
                        'Vào: ${s['checkInAt']?.toString().split('T').last.substring(0, 5) ?? '--:--'}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                    if (checkedIn && checkedOut) const Text('   •   '),
                    if (checkedOut) ...[
                      const Icon(Icons.logout_rounded, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Ra: ${s['checkOutAt']?.toString().split('T').last.substring(0, 5) ?? '--:--'}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),

            // Hàng nút hành động Check-in / Check-out
            if (!isToday)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 14, color: AppColors.textMuted),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Chỉ có thể chấm công trong ngày của ca làm.',
                        style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                      ),
                    ),
                  ],
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: checkedIn ? null : () => _attendance(s, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        disabledBackgroundColor: Colors.grey.shade200,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                      icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                      label: Text(
                        checkedIn ? 'Đã Check-in' : 'Check-in',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: !checkedIn || checkedOut
                          ? null
                          : () => _attendance(s, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(
                          color: !checkedIn || checkedOut ? Colors.grey.shade300 : AppColors.primary,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                      ),
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: Text(
                        checkedOut ? 'Đã Check-out' : 'Check-out',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 3: LỊCH SỬ CHẤM CÔNG
  // ==========================================
  Widget _buildHistoryTab() {
    if (_loading) {
      return const AppLoading(message: 'Đang tải lịch sử chấm công...');
    }
    if (_error != null) {
      return AppError(message: _error!, onRetry: _load);
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          Row(
            children: [
              const Icon(Icons.history_edu_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Lịch sử chấm công (${_history.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_history.isEmpty)
            const EmptyState(
              icon: Icons.history_toggle_off_rounded,
              title: 'Chưa có bản ghi chấm công',
              message: 'Lịch sử chấm công của bạn sẽ xuất hiện tại đây sau khi hoàn tất ca làm.',
            )
          else
            ..._history.map(_buildHistoryCard),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> h) {
    final status = h['attendance_status']?.toString() ?? 'PRESENT';
    Color badgeColor = AppColors.secondary;
    Color badgeBg = const Color(0xFFE8F5E9);
    String statusText = 'Đúng giờ';

    if (status == 'LATE') {
      badgeColor = AppColors.statusLate;
      badgeBg = const Color(0xFFFEF3C7);
      statusText = 'Đi muộn';
    } else if (status == 'INVALID_LOCATION') {
      badgeColor = AppColors.statusAbsent;
      badgeBg = const Color(0xFFFEE2E2);
      statusText = 'Sai GPS';
    }

    final dateStr = h['work_date']?.toString() ?? '';
    final shiftName = h['shift_name']?.toString() ?? 'Ca làm';
    final areaName = h['area_name']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            status == 'PRESENT'
                ? Icons.verified_rounded
                : status == 'LATE'
                ? Icons.access_time_filled_rounded
                : Icons.location_off_rounded,
            color: badgeColor,
            size: 22,
          ),
        ),
        title: Text(
          '$dateStr · $shiftName',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (areaName.isNotEmpty)
                Text(
                  'Khu vực: $areaName',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/*
 * Retired merge artifact: the current attendance flow above is the only
 * supported route. It requires camera QR scanning and a fresh GPS reading;
 * this legacy wizard accepted manual QR input and must never be reachable.
 */
/*
class _AttendanceWizardSheet extends StatefulWidget {
  const _AttendanceWizardSheet({
    required this.schedule,
    required this.isCheckIn,
    required this.employeeId,
    required this.headers,
    required this.baseUrl,
  });

  final Map<String, dynamic> schedule;
  final bool isCheckIn;
  final int employeeId;
  final Map<String, String> headers;
  final String baseUrl;

  @override
  State<_AttendanceWizardSheet> createState() => _AttendanceWizardSheetState();
}

class _AttendanceWizardSheetState extends State<_AttendanceWizardSheet> {
  int _currentStep = 0; // 0: QR, 1: GPS, 2: Xác nhận, 3: Kết quả
  final TextEditingController _qrController = TextEditingController();

  LocationSample? _location;
  bool _fetchingGps = false;
  String? _gpsError;

  bool _submitting = false;
  String? _submitError;
  String? _submitSuccessMessage;

  @override
  void dispose() {
    _qrController.dispose();
    super.dispose();
  }

  // Bước 2: Kích hoạt GPS
  Future<void> _fetchLocation() async {
    setState(() {
      _fetchingGps = true;
      _gpsError = null;
    });
    try {
      final loc = await getCurrentLocation();
      if (mounted) {
        setState(() {
          _location = loc;
          _fetchingGps = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _fetchingGps = false;
          _gpsError = AppError.friendlyMessage(e);
        });
      }
    }
  }

  // Bước 3: Gửi chấm công lên backend
  Future<void> _submitAttendance() async {
    setState(() {
      _submitting = true;
      _submitError = null;
    });

    try {
      final endpoint = widget.isCheckIn ? 'check-in' : 'check-out';
      final response = await http.post(
        Uri.parse('${widget.baseUrl}/attendance/$endpoint'),
        headers: widget.headers,
        body: jsonEncode({
          'scheduleId': widget.schedule['scheduleId'],
          'employeeId': widget.employeeId,
          'qrToken': _qrController.text.trim(),
          'latitude': _location?.latitude,
          'longitude': _location?.longitude,
          'accuracyMeters': _location?.accuracyMeters,
        }),
      );

      final data = _asMap(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError(
          data['message']?.toString() ?? 'Chấm công thất bại (${response.statusCode}).',
        );
      }

      if (mounted) {
        setState(() {
          _submitting = false;
          _submitSuccessMessage =
              data['message']?.toString() ??
              (widget.isCheckIn ? 'Check-in thành công!' : 'Check-out thành công!');
          _currentStep = 3; // chuyển sang bước 4: Kết quả
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _submitError = AppError.friendlyMessage(e);
          _currentStep = 3; // chuyển sang bước 4 để báo lỗi rõ
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final title = widget.isCheckIn ? 'Quy trình Check-in' : 'Quy trình Check-out';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${widget.schedule['shiftName'] ?? 'Ca làm'} · ${widget.schedule['workDate'] ?? ''}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context, _submitSuccessMessage != null),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.divider),

          // 4-step Stepper Indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                _buildStepBadge(0, 'Quét QR'),
                _buildStepDivider(0),
                _buildStepBadge(1, 'GPS'),
                _buildStepDivider(1),
                _buildStepBadge(2, 'Gửi'),
                _buildStepDivider(2),
                _buildStepBadge(3, 'Kết quả'),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.divider),

          // Content của Step hiện tại
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: switch (_currentStep) {
                0 => _buildStep1Qr(),
                1 => _buildStep2Gps(),
                2 => _buildStep3Confirm(),
                _ => _buildStep4Result(),
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepBadge(int index, String label) {
    final isActive = _currentStep == index;
    final isDone = _currentStep > index;

    Color bg = const Color(0xFFF3F4F6);
    Color fg = AppColors.textSecondary;

    if (isActive) {
      bg = AppColors.primary;
      fg = Colors.white;
    } else if (isDone) {
      bg = AppColors.secondary;
      fg = Colors.white;
    }

    return Expanded(
      child: Column(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: bg,
            child: isDone
                ? const Icon(Icons.check, size: 14, color: Colors.white)
                : Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: fg,
                    ),
                  ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildStepDivider(int afterIndex) {
    final isDone = _currentStep > afterIndex;
    return Container(
      width: 16,
      height: 2,
      margin: const EdgeInsets.only(bottom: 14),
      color: isDone ? AppColors.secondary : AppColors.divider,
    );
  }

  // BƯỚC 1: QUÉT QR
  Widget _buildStep1Qr() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.qr_code_scanner_rounded,
              size: 44,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Bước 1: Quét mã QR ca làm việc',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Quét mã QR được quản lý hiển thị tại quầy hoặc dán tại khu vực làm việc.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),

        // Nút mở camera quét QR
        FilledButton.icon(
          onPressed: () async {
            final code = await Navigator.of(context).push<String>(
              MaterialPageRoute(builder: (_) => const QrScannerPage()),
            );
            if (code != null && code.trim().isNotEmpty) {
              setState(() {
                _qrController.text = code.trim();
                _currentStep = 1; // tự động qua bước GPS
              });
              _fetchLocation();
            }
          },
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          icon: const Icon(Icons.camera_alt_rounded),
          label: const Text('Mở camera quét QR'),
        ),
        const SizedBox(height: 16),

        const Row(
          children: [
            Expanded(child: Divider()),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'hoặc nhập mã thủ công',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ),
            Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 16),

        TextField(
          controller: _qrController,
          decoration: InputDecoration(
            labelText: 'Mã QR Token',
            hintText: 'Nhập chuỗi mã QR...',
            prefixIcon: const Icon(Icons.pin_rounded),
            suffixIcon: _qrController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () => setState(() => _qrController.clear()),
                  )
                : null,
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 20),

        FilledButton(
          onPressed: _qrController.text.trim().isEmpty
              ? null
              : () {
                  setState(() => _currentStep = 1);
                  _fetchLocation();
                },
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Tiếp tục: Xác minh GPS >'),
        ),
      ],
    );
  }

  // BƯỚC 2: XÁC MINH GPS
  Widget _buildStep2Gps() {
    final requireGps = widget.schedule['requireLocation'] == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _location != null
                  ? const Color(0xFFE8F5E9)
                  : _gpsError != null
                  ? const Color(0xFFFEF2F2)
                  : AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              _location != null
                  ? Icons.location_on_rounded
                  : _gpsError != null
                  ? Icons.location_off_rounded
                  : Icons.satellite_alt_rounded,
              size: 44,
              color: _location != null
                  ? AppColors.secondary
                  : _gpsError != null
                  ? AppColors.statusAbsent
                  : AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Bước 2: Xác minh vị trí GPS',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          requireGps
              ? 'Ca làm việc bắt buộc kiểm tra GPS trong bán kính siêu thị.'
              : 'Ca làm không bắt buộc GPS, nhưng định vị sẽ giúp xác thực nhanh hơn.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),

        if (_fetchingGps)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: AppLoading(message: 'Đang định vị tọa độ GPS...'),
          )
        else if (_location != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF86EFAC)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.check_circle_rounded, color: AppColors.secondary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Đã lấy vị trí thành công',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF166534),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Tọa độ: ${_location!.latitude.toStringAsFixed(6)}, ${_location!.longitude.toStringAsFixed(6)}',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF166534)),
                ),
                Text(
                  'Độ chính xác: ±${_location!.accuracyMeters.toStringAsFixed(1)} mét',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF166534)),
                ),
              ],
            ),
          )
        else if (_gpsError != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFCA5A5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.error_outline_rounded, color: AppColors.statusAbsent, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Không lấy được vị trí GPS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF991B1B),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _gpsError!,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF991B1B)),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _fetchLocation,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Thử lấy lại vị trí'),
                ),
              ],
            ),
          ),

        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep = 0),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Quay lại QR'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: (requireGps && _location == null) || _fetchingGps
                    ? null
                    : () => setState(() => _currentStep = 2),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Tiếp tục: Xác nhận >'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // BƯỚC 3: XÁC NHẬN & GỬI CHẤM CÔNG
  Widget _buildStep3Confirm() {
    final typeName = widget.isCheckIn ? 'Check-in (Bắt đầu ca)' : 'Check-out (Kết thúc ca)';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.send_rounded,
              size: 44,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Bước 3: Xác nhận thông tin chấm công',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        const Text(
          'Vui lòng kiểm tra lại thông tin trước khi gửi lên máy chủ.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.divider),
          ),
          child: Column(
            children: [
              _buildConfirmRow('Loại hành động', typeName, isBold: true),
              const Divider(height: 16),
              _buildConfirmRow(
                'Ca làm',
                '${widget.schedule['shiftName'] ?? 'Ca'} (${widget.schedule['startTime'] ?? ''} - ${widget.schedule['endTime'] ?? ''})',
              ),
              const Divider(height: 16),
              _buildConfirmRow(
                'Khu vực',
                '${widget.schedule['areaName'] ?? ''} · ${widget.schedule['floorName'] ?? ''}',
              ),
              const Divider(height: 16),
              _buildConfirmRow(
                'Mã QR',
                _qrController.text.length > 8
                    ? '${_qrController.text.substring(0, 4)}...${_qrController.text.substring(_qrController.text.length - 4)}'
                    : _qrController.text,
              ),
              const Divider(height: 16),
              _buildConfirmRow(
                'Vị trí GPS',
                _location != null
                    ? '${_location!.latitude.toStringAsFixed(4)}, ${_location!.longitude.toStringAsFixed(4)} (±${_location!.accuracyMeters.toStringAsFixed(0)}m)'
                    : 'Không cung cấp (Ca không bắt buộc)',
              ),
              const Divider(height: 16),
              _buildConfirmRow(
                'Thời gian ghi nhận',
                DateFormat('HH:mm:ss · dd/MM/yyyy').format(DateTime.now()),
                isBold: true,
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        if (_submitting)
          const AppLoading(message: 'Đang gửi dữ liệu chấm công...')
        else
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _currentStep = 1),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Quay lại GPS'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _submitAttendance,
                  style: FilledButton.styleFrom(
                    backgroundColor: widget.isCheckIn ? AppColors.secondary : AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text('Gửi chấm công'),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildConfirmRow(String label, String value, {bool isBold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  // BƯỚC 4: KẾT QUẢ CHẤM CÔNG
  Widget _buildStep4Result() {
    final isSuccess = _submitSuccessMessage != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: isSuccess ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
              size: 54,
              color: isSuccess ? AppColors.secondary : AppColors.statusAbsent,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          isSuccess ? 'Chấm công thành công!' : 'Chấm công chưa thành công',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isSuccess ? const Color(0xFF166534) : const Color(0xFF991B1B),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSuccess ? const Color(0xFFF0FDF4) : const Color(0xFFFEF2F2),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSuccess ? const Color(0xFF86EFAC) : const Color(0xFFFCA5A5),
            ),
          ),
          child: Text(
            isSuccess ? _submitSuccessMessage! : _submitError ?? 'Đã xảy ra sự cố trong quá trình gửi.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isSuccess ? const Color(0xFF166534) : const Color(0xFF991B1B),
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 24),
        if (isSuccess)
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.secondary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Hoàn tất & Cập nhật ca làm'),
          )
        else
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _currentStep = 2),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Thử lại'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Đóng'),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
*/

// Helper methods
List<Map<String, dynamic>> _asList(String body) {
  try {
    final value = jsonDecode(body);
    return value is List
        ? value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
        : [];
  } catch (_) {
    return [];
  }
}

Map<String, dynamic> _asMap(String body) {
  try {
    final value = jsonDecode(body);
    return value is Map ? Map<String, dynamic>.from(value) : {};
  } catch (_) {
    return {};
  }
}

void _ensureOk(http.Response response) {
  if (response.statusCode < 200 || response.statusCode >= 300) {
    final data = _asMap(response.body);
    throw StateError(
      data['message']?.toString() ??
          'Yêu cầu thất bại (${response.statusCode}).',
    );
  }
}

String _message(Object error) =>
    error.toString().replaceFirst('Bad state: ', '');
