import '../../core/widgets/app_workspace.dart';
import 'dart:convert';

import 'location/location_service.dart';
import 'qr_scanner_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
  });
  final int employeeId;
  final String idToken, fullName, email, roleCode, roleName;
  final Future<void> Function() onLogout;
  @override
  State<EmployeeWorkspace> createState() => _EmployeeWorkspaceState();
}

class _EmployeeWorkspaceState extends State<EmployeeWorkspace> {
  int _tab = 0;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _schedules = [], _history = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Map<String, String> get _headers => {
    'Authorization': 'Bearer ${widget.idToken}',
    'Content-Type': 'application/json',
  };
  String get _base {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return override;
    return kIsWeb ? 'http://localhost:8080/api' : 'http://10.0.2.2:8080/api';
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
      final scheduleUri =
          Uri.parse('$_base/employees/${widget.employeeId}/schedules').replace(
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
      if (mounted)
        setState(() {
          _schedules = _asList(results[0].body);
          _history = _asList(results[1].body);
        });
    } catch (e) {
      if (mounted) setState(() => _error = _message(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _attendance(Map<String, dynamic> schedule, bool checkIn) async {
    final token = await _askForQr(checkIn);
    if (token == null) return;
    try {
      LocationSample? location;
      try {
        location = await getCurrentLocation();
      } on Object catch (error) {
        if (schedule['requireLocation'] == true) rethrow;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Không lấy được GPS: ${_message(error)}. Hệ thống vẫn tiếp tục vì ca này không bắt buộc GPS.',
              ),
            ),
          );
        }
      }
      final response = await http.post(
        Uri.parse('$_base/attendance/${checkIn ? 'check-in' : 'check-out'}'),
        headers: _headers,
        body: jsonEncode({
          'scheduleId': schedule['scheduleId'],
          'employeeId': widget.employeeId,
          'qrToken': token,
          'latitude': location?.latitude,
          'longitude': location?.longitude,
          'accuracyMeters': location?.accuracyMeters,
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
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_message(e))));
    }
  }

  Future<String?> _askForQr(bool checkIn) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(checkIn ? 'Check-in bằng QR' : 'Check-out bằng QR'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Mã QR',
            hintText: 'Quét hoặc nhập mã do quản lý tạo',
            suffixIcon: IconButton(
              tooltip: 'Quét QR bằng camera',
              icon: const Icon(Icons.qr_code_scanner),
              onPressed: () async {
                final code = await Navigator.of(context).push<String>(
                  MaterialPageRoute(builder: (_) => const QrScannerPage()),
                );
                if (code != null) controller.text = code;
              },
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AppWorkspace(
    title: 'Không gian nhân viên',
    selectedIndex: _tab,
    onSelected: (value) => setState(() => _tab = value),
    destinations: const [
      WorkspaceDestination('Tổng quan', Icons.dashboard_outlined),
      WorkspaceDestination('Lịch làm', Icons.calendar_month_outlined),
      WorkspaceDestination('Chấm công', Icons.history_rounded),
    ],
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Không gian nhân viên'),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại',
          ),
          IconButton(
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _Error(message: _error!, retry: _load)
          : IndexedStack(
              index: _tab,
              children: [_overview(), _schedulePage(), _historyPage()],
            ),
    ),
  );
  Widget _overview() {
    final todaySchedules = _schedules
        .where((s) => s['workDate']?.toString() == _today)
        .toList();
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          'Xin chào, ${widget.fullName}',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 6),
        Text(widget.email),
        const SizedBox(height: 18),
        Card(
          child: ListTile(
            leading: const Icon(Icons.badge_outlined),
            title: const Text('Vai trò'),
            subtitle: Text('${widget.roleName} (${widget.roleCode})'),
          ),
        ),
        const SizedBox(height: 18),
        Text('Ca làm hôm nay', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (todaySchedules.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Hôm nay bạn chưa có lịch làm.'),
            ),
          ),
        ...todaySchedules.map(_scheduleCard),
      ],
    );
  }

  Widget _schedulePage() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Text(
        'Lịch làm gần đây và sắp tới',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 6),
      const Text('Hiển thị 7 ngày trước và 30 ngày tới.'),
      const SizedBox(height: 12),
      if (_schedules.isEmpty) const Text('Không có lịch làm.'),
      ..._schedules.map(_scheduleCard),
    ],
  );

  Widget _scheduleCard(Map<String, dynamic> s) {
    final checkedIn = s['checkInAt'] != null;
    final checkedOut = s['checkOutAt'] != null;
    final isToday = s['workDate']?.toString() == _today;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${s['workDate'] ?? ''} · ${s['shiftName'] ?? 'Ca làm'}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text('${s['startTime'] ?? ''} - ${s['endTime'] ?? ''}'),
            const SizedBox(height: 4),
            Text('${s['areaName'] ?? ''} · ${s['floorName'] ?? ''}'),
            const SizedBox(height: 12),
            if (!isToday)
              const Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text(
                  'Chỉ có thể chấm công trong ngày làm.',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: !isToday || checkedIn
                        ? null
                        : () => _attendance(s, true),
                    icon: const Icon(Icons.login),
                    label: const Text('Check-in'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: !isToday || !checkedIn || checkedOut
                        ? null
                        : () => _attendance(s, false),
                    icon: const Icon(Icons.logout),
                    label: const Text('Check-out'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _historyPage() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Text(
        'Lịch sử chấm công',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 12),
      if (_history.isEmpty) const Text('Chưa có lịch sử chấm công.'),
      ..._history.map(
        (h) => Card(
          child: ListTile(
            leading: const Icon(Icons.fact_check_outlined),
            title: Text('${h['work_date'] ?? ''} · ${h['shift_name'] ?? ''}'),
            subtitle: Text(
              '${h['area_name'] ?? ''}\nTrạng thái: ${h['attendance_status'] ?? ''}',
            ),
            isThreeLine: true,
          ),
        ),
      ),
    ],
  );
}

class _Error extends StatelessWidget {
  const _Error({required this.message, required this.retry});
  final String message;
  final Future<void> Function() retry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: retry, child: const Text('Thử lại')),
        ],
      ),
    ),
  );
}

List<Map<String, dynamic>> _asList(String body) {
  final value = jsonDecode(body);
  return value is List
      ? value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
      : [];
}

Map<String, dynamic> _asMap(String body) {
  final value = jsonDecode(body);
  return value is Map ? Map<String, dynamic>.from(value) : {};
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
