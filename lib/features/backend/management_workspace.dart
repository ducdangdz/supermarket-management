import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/services/device_identity_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_workspace.dart';
import '../auth/data/account_auth_api.dart';

class ManagementWorkspace extends StatefulWidget {
  const ManagementWorkspace({
    super.key,
    required this.idToken,
    required this.fullName,
    required this.roleCode,
    required this.onLogout,
  });
  final String idToken, fullName, roleCode;
  final Future<void> Function() onLogout;
  @override
  State<ManagementWorkspace> createState() => _ManagementWorkspaceState();
}

class _ManagementWorkspaceState extends State<ManagementWorkspace> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _employees = [],
      _shifts = [],
      _areas = [],
      _assignedSchedules = [];
  int? _employeeId, _shiftId, _areaId;
  DateTime _date = DateTime.now();
  int _tab = 0;

  String get _base {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return override;
    return accountApiBaseUrl;
  }

  Map<String, String> get _headers => {
    'Authorization': 'Bearer ${widget.idToken}',
    'X-Device-Id': DeviceIdentityService.currentId,
    'Content-Type': 'application/json',
  };
  bool get _canQr => widget.roleCode == 'ADMIN' || widget.roleCode == 'MANAGER';
  String _formatDate(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
  String get _dateText => _formatDate(_date);
  String get _todayText {
    final now = DateTime.now();
    return _formatDate(now);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final scheduleUri = Uri.parse('$_base/management/schedules').replace(
        queryParameters: {
          'from': _todayText,
          'to': _formatDate(DateTime.now().add(const Duration(days: 30))),
        },
      );
      final results = await Future.wait([
        http.get(Uri.parse('$_base/employees'), headers: _headers),
        http.get(Uri.parse('$_base/management/shifts'), headers: _headers),
        http.get(Uri.parse('$_base/management/work-areas'), headers: _headers),
        http.get(scheduleUri, headers: _headers),
      ]);
      for (final result in results) _ok(result);
      if (!mounted) return;
      setState(() {
        _employees = _list(
          results[0].body,
        ).where((e) => e['employmentStatus'] == 'ACTIVE').toList();
        _shifts = _list(results[1].body);
        _areas = _list(results[2].body);
        _assignedSchedules = _list(results[3].body);
      });
    } catch (error) {
      if (mounted) setState(() => _error = _message(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selected != null) setState(() => _date = selected);
  }

  Future<void> _createSchedule() async {
    if (_employeeId == null || _shiftId == null || _areaId == null) {
      _notice('Hãy chọn nhân viên, ca làm và khu vực.');
      return;
    }
    try {
      final response = await http.post(
        Uri.parse('$_base/management/schedules'),
        headers: _headers,
        body: jsonEncode({
          'employeeId': _employeeId,
          'shiftId': _shiftId,
          'workAreaId': _areaId,
          'workDate': _dateText,
        }),
      );
      _ok(response);
      _notice('Đã phân công lịch làm cho nhân viên.');
      await _load();
    } catch (error) {
      _notice(_message(error));
    }
  }

  Future<void> _cancelSchedule(Map<String, dynamic> schedule) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hủy lịch làm?'),
        content: Text(
          'Hủy ca ${schedule['shift_name']} của ${schedule['full_name']} vào ngày ${schedule['work_date']}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Không'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hủy lịch'),
          ),
        ],
      ),
    );
    if (accepted != true) return;
    try {
      final response = await http.patch(
        Uri.parse(
          '$_base/management/schedules/${schedule['schedule_id']}/cancel',
        ),
        headers: _headers,
      );
      _ok(response);
      _notice('Đã hủy lịch làm.');
      await _load();
    } catch (error) {
      _notice(_message(error));
    }
  }

  Future<void> _createQr(String type) async {
    if (_shiftId == null || _areaId == null) {
      _notice('Hãy chọn ca làm và khu vực trước.');
      return;
    }
    try {
      final response = await http.post(
        Uri.parse('$_base/management/qr-sessions'),
        headers: _headers,
        body: jsonEncode({
          'shiftId': _shiftId,
          'workAreaId': _areaId,
          'sessionType': type,
          'expiresInSeconds': 120,
        }),
      );
      _ok(response);
      final data = _map(response.body);
      if (!mounted) return;
      final token = data['token']?.toString() ?? '';
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(type == 'CHECK_IN' ? 'QR Check-in' : 'QR Check-out'),
          content: SizedBox(
            width: 280,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                QrImageView(
                  data: token,
                  version: QrVersions.auto,
                  size: 220,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 12),
                Text('Hiệu lực trong ngày $_todayText, tối đa 2 phút.'),
                const SizedBox(height: 4),
                const Text('Nhân viên quét mã này hoặc nhập chuỗi bên dưới.'),
                const SizedBox(height: 8),
                SelectableText(
                  token,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
          ],
        ),
      );
    } catch (error) {
      _notice(_message(error));
    }
  }

  void _notice(String text) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) => AppWorkspace(
    title: 'Quản lý vận hành',
    selectedIndex: _tab,
    onSelected: (value) => setState(() => _tab = value),
    destinations: [
      const WorkspaceDestination('Phân ca', Icons.assignment_outlined),
      const WorkspaceDestination('Lịch đã phân', Icons.calendar_month_outlined),
      if (_canQr) const WorkspaceDestination('Mã QR', Icons.qr_code_rounded),
    ],
    child: Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Quản lý vận hành', style: TextStyle(fontWeight: FontWeight.w800)),
            Text('Lập lịch và điều phối ca làm', style: TextStyle(fontSize: 12, color: Colors.blueGrey.shade500)),
          ],
        ),
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
              children: [_assignPage(), _assignedPage(), if (_canQr) _qrPage()],
            ),
    ),
  );
  Widget _assignPage() => ListView(
    padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
    children: [
      _pageHeading('Phân công lịch làm', 'Chọn nhân sự, ca làm và khu vực để tạo lịch nhanh chóng.'),
      const SizedBox(height: 20),
      _summaryStrip(),
      const SizedBox(height: 20),
      _selectionCard(showEmployee: true),
      const SizedBox(height: 20),
      FilledButton.icon(
        onPressed: _createSchedule,
        icon: const Icon(Icons.save_outlined),
        label: const Text('Lưu phân công'),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    ],
  );
  Widget _assignedPage() => ListView(
    padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
    children: [
      _pageHeading('Lịch đã phân', 'Theo dõi các ca đã tạo từ hôm nay đến 30 ngày tới.'),
      const SizedBox(height: 20),
      if (_assignedSchedules.isEmpty) _emptyPanel('Chưa có lịch nào', 'Các ca được phân công sẽ xuất hiện ở đây.'),
      ..._assignedSchedules.map((s) {
        final cancelled = s['schedule_status'] == 'CANCELLED';
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: cancelled ? const Color(0xFFFECACA) : AppColors.divider),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: .025), blurRadius: 14, offset: const Offset(0, 5))],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            leading: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: cancelled ? const Color(0xFFFEF2F2) : AppColors.primaryLight, borderRadius: BorderRadius.circular(14)),
              child: Icon(cancelled ? Icons.event_busy_rounded : Icons.event_available_rounded, color: cancelled ? AppColors.statusAbsent : AppColors.primary),
            ),
            title: Text('${s['work_date']} · ${s['shift_name']}', style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text('${s['full_name']} · ${s['employee_code']}\n${s['area_name']} · ${s['floor_name']}  •  ${s['start_time']} - ${s['end_time']}', style: const TextStyle(height: 1.5)),
            ),
            isThreeLine: true,
            trailing: cancelled
                ? const _StatusPill(label: 'ĐÃ HỦY', color: AppColors.statusAbsent)
                : IconButton(icon: const Icon(Icons.cancel_outlined), tooltip: 'Hủy lịch', onPressed: () => _cancelSchedule(s)),
          ),
        );
      }),
    ],
  );
  Widget _qrPage() => ListView(
    padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
    children: [
      _pageHeading('Tạo mã QR chấm công', 'Mã QR có hiệu lực trong 2 phút và chỉ dùng cho đúng ca, đúng khu vực.'),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: const Color(0xFFEAF4FF), borderRadius: BorderRadius.circular(18)),
        child: Row(children: [
          const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.today_rounded, color: AppColors.primary)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Ngày hiệu lực', style: TextStyle(fontWeight: FontWeight.w700)),
            Text('Hôm nay · $_todayText', style: const TextStyle(color: AppColors.textSecondary)),
          ])),
        ]),
      ),
      const SizedBox(height: 16),
      _selectionCard(showEmployee: false),
      const SizedBox(height: 20),
      Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () => _createQr('CHECK_IN'),
              icon: const Icon(Icons.login),
              label: const Text('Tạo QR vào'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _createQr('CHECK_OUT'),
              icon: const Icon(Icons.logout),
              label: const Text('Tạo QR ra'),
            ),
          ),
        ],
      ),
    ],
  );
  Widget _selectionCard({required bool showEmployee}) => Card(
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppColors.divider)),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(showEmployee ? 'Thông tin phân công' : 'Thiết lập phiên QR', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 18),
          if (showEmployee) ...[
            _drop<int>(
              'Nhân viên',
              _employeeId,
              _employees,
              'employeeId',
              (e) => '${e['fullName']} · ${e['employeeCode']}',
              (v) => setState(() => _employeeId = v),
            ),
            const SizedBox(height: 12),
          ],
          _drop<int>(
            'Ca làm',
            _shiftId,
            _shifts,
            'shift_id',
            (s) => '${s['shift_name']} · ${s['start_time']} - ${s['end_time']}',
            (v) => setState(() => _shiftId = v),
          ),
          const SizedBox(height: 12),
          _drop<int>(
            'Khu vực',
            _areaId,
            _areas,
            'work_area_id',
            (a) => '${a['area_name']} · ${a['floor_name']}',
            (v) => setState(() => _areaId = v),
          ),
          if (showEmployee) ...[
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: const Text('Ngày làm'),
              subtitle: Text(_dateText),
              trailing: TextButton(
                onPressed: _pickDate,
                child: const Text('Chọn ngày'),
              ),
            ),
          ],
        ],
      ),
    ),
  );
  Widget _drop<T>(
    String label,
    T? value,
    List<Map<String, dynamic>> items,
    String key,
    String Function(Map<String, dynamic>) labelOf,
    void Function(T?) onChanged,
  ) => DropdownButtonFormField<T>(
    value: value,
    isExpanded: true,
    decoration: InputDecoration(
      labelText: label,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.divider)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.divider)),
    ),
    items: items.map((item) {
      final raw = item[key];
      final id = raw is num ? raw.toInt() : raw;
      return DropdownMenuItem<T>(
        value: id as T,
        child: Text(labelOf(item), overflow: TextOverflow.ellipsis),
      );
    }).toList(),
    onChanged: onChanged,
  );

  Widget _pageHeading(String title, String subtitle) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
      const SizedBox(height: 6),
      Text(subtitle, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4)),
    ],
  );

  Widget _summaryStrip() => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(colors: [Color(0xFF0F4C6E), Color(0xFF176E91)]),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(children: [
      const CircleAvatar(radius: 23, backgroundColor: Color(0x33FFFFFF), child: Icon(Icons.admin_panel_settings_outlined, color: Colors.white)),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Xin chào, ${widget.fullName}', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 3),
        Text('${_employees.length} nhân viên sẵn sàng phân ca · ${_assignedSchedules.length} lịch đã tạo', style: const TextStyle(color: Color(0xFFD6F0FA), fontSize: 12)),
      ])),
    ]),
  );

  Widget _emptyPanel(String title, String detail) => Container(
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.divider)),
    child: Column(children: [
      const Icon(Icons.calendar_month_outlined, size: 38, color: AppColors.textMuted),
      const SizedBox(height: 10), Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      const SizedBox(height: 4), Text(detail, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
    ]),
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(color: color.withValues(alpha: .1), borderRadius: BorderRadius.circular(20)),
    child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color)),
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

List<Map<String, dynamic>> _list(String body) {
  final value = jsonDecode(body);
  return value is List
      ? value.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
      : [];
}

Map<String, dynamic> _map(String body) {
  final value = jsonDecode(body);
  return value is Map ? Map<String, dynamic>.from(value) : {};
}

void _ok(http.Response response) {
  if (response.statusCode < 200 || response.statusCode >= 300) {
    final data = _map(response.body);
    throw StateError(
      data['message']?.toString() ??
          'Yêu cầu thất bại (${response.statusCode}).',
    );
  }
}

String _message(Object error) =>
    error.toString().replaceFirst('Bad state: ', '');
