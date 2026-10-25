import '../../core/widgets/app_workspace.dart';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';

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
    return kIsWeb ? 'http://localhost:8080/api' : 'http://10.0.2.2:8080/api';
  }

  Map<String, String> get _headers => {
    'Authorization': 'Bearer ${widget.idToken}',
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
      appBar: AppBar(
        title: const Text('Quản lý vận hành'),
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
    padding: const EdgeInsets.all(20),
    children: [
      Text(
        'Phân công lịch làm',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 6),
      Text('Người thực hiện: ${widget.fullName}'),
      const SizedBox(height: 20),
      _selectionCard(showEmployee: true),
      const SizedBox(height: 16),
      FilledButton.icon(
        onPressed: _createSchedule,
        icon: const Icon(Icons.save_outlined),
        label: const Text('Lưu phân công'),
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
      ),
    ],
  );
  Widget _assignedPage() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Text('Lịch đã phân', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 6),
      const Text('Hiển thị lịch từ hôm nay đến 30 ngày tới.'),
      const SizedBox(height: 12),
      if (_assignedSchedules.isEmpty) const Text('Chưa có lịch nào.'),
      ..._assignedSchedules.map((s) {
        final cancelled = s['schedule_status'] == 'CANCELLED';
        return Card(
          child: ListTile(
            leading: Icon(cancelled ? Icons.event_busy : Icons.event_note),
            title: Text('${s['work_date']} · ${s['shift_name']}'),
            subtitle: Text(
              '${s['full_name']} · ${s['employee_code']}\n${s['area_name']} · ${s['floor_name']}\n${s['start_time']} - ${s['end_time']} · ${cancelled ? 'ĐÃ HỦY' : 'ĐÃ PHÂN'}',
            ),
            isThreeLine: true,
            trailing: cancelled
                ? null
                : IconButton(
                    icon: const Icon(Icons.cancel_outlined),
                    tooltip: 'Hủy lịch',
                    onPressed: () => _cancelSchedule(s),
                  ),
          ),
        );
      }),
    ],
  );
  Widget _qrPage() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      Text(
        'Tạo mã QR chấm công',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 6),
      const Text(
        'Mỗi mã có hiệu lực 2 phút. Gửi mã này cho nhân viên đúng khu vực.',
      ),
      const SizedBox(height: 16),
      Card(
        child: ListTile(
          leading: const Icon(Icons.event_available),
          title: const Text('Ngày hiệu lực'),
          subtitle: Text('Hôm nay · $_todayText'),
        ),
      ),
      const SizedBox(height: 12),
      _selectionCard(showEmployee: false),
      const SizedBox(height: 16),
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
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
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
      border: const OutlineInputBorder(),
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
