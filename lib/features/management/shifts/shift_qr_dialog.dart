import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/network/team_api.dart';
import '../../../models/models.dart';

class ShiftQrDialog extends StatefulWidget {
  const ShiftQrDialog({super.key, required this.shift, this.api, this.clock});
  final Shift shift;
  final TeamApi? api;
  final DateTime Function()? clock;
  @override
  State<ShiftQrDialog> createState() => _ShiftQrDialogState();
}

class _ShiftQrDialogState extends State<ShiftQrDialog> {
  late final TeamApi api;
  List<Map<String, dynamic>> areas = [];
  int? areaId;
  String type = 'CHECK_IN';
  String? token, error;
  DateTime? expiresAt;
  bool loading = true, busy = false;
  Timer? timer;
  DateTime get now => widget.clock?.call() ?? DateTime.now();
  int get remaining => expiresAt == null
      ? 0
      : expiresAt!.difference(now).inSeconds.clamp(0, 300);
  @override
  void initState() {
    super.initState();
    api = widget.api ?? TeamApi.active!;
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final rows = await api.request('/management/work-areas') as List;
      final filtered = rows
          .map((e) => Map<String, dynamic>.from(e))
          .where((a) => a['branch_id'] == widget.shift.branchId)
          .toList();
      if (mounted)
        setState(() {
          areas = filtered;
          areaId = areas.isEmpty
              ? null
              : (areas.first['work_area_id'] as num).toInt();
        });
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void reset() {
    timer?.cancel();
    token = null;
    expiresAt = null;
    error = null;
  }

  Future<void> generate() async {
    if (busy || areaId == null) return;
    setState(() {
      busy = true;
      reset();
    });
    try {
      final data = await api.request(
        '/management/qr-sessions',
        method: 'POST',
        body: {
          'shiftId': widget.shift.shiftId,
          'workAreaId': areaId,
          'sessionType': type,
          'expiresInSeconds': 300,
        },
      );
      final value = data['token'];
      final expiry = DateTime.tryParse(data['expiresAt']?.toString() ?? '');
      if (value is! String || value.isEmpty || expiry == null)
        throw StateError('Máy chủ chưa trả về mã QR hợp lệ.');
      if (!mounted) return;
      setState(() {
        token = value;
        expiresAt = expiry;
      });
      timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
        if (remaining == 0) timer?.cancel();
      });
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Tạo QR chấm công'),
    content: SizedBox(
      width: 420,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.shift.shiftName,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            const Text(
              'Chọn đúng khu vực và loại QR. Mã có hiệu lực 5 phút kể từ lúc tạo.',
              style: TextStyle(fontSize: 12, color: Colors.blueGrey),
            ),
            const SizedBox(height: 20),
            if (loading)
              const Center(child: CircularProgressIndicator())
            else if (areas.isEmpty)
              const Text(
                'Chưa có khu vực hoạt động trong chi nhánh của ca này.',
              )
            else ...[
              DropdownButtonFormField<int>(
                initialValue: areaId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Khu vực làm việc',
                ),
                items: [
                  for (final a in areas)
                    DropdownMenuItem(
                      value: (a['work_area_id'] as num).toInt(),
                      child: Text(
                        '${a['area_name']} · ${a['floor_name']}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: busy
                    ? null
                    : (v) => setState(() {
                        areaId = v;
                        reset();
                      }),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: const InputDecoration(labelText: 'Loại mã QR'),
                items: const [
                  DropdownMenuItem(
                    value: 'CHECK_IN',
                    child: Text('Vào ca (Check-in)'),
                  ),
                  DropdownMenuItem(
                    value: 'CHECK_OUT',
                    child: Text('Ra ca (Check-out)'),
                  ),
                ],
                onChanged: busy
                    ? null
                    : (v) => setState(() {
                        type = v!;
                        reset();
                      }),
              ),
            ],
            if (error != null) ...[
              const SizedBox(height: 16),
              Text(error!, style: const TextStyle(color: Colors.red)),
              if (areas.isEmpty)
                TextButton(
                  onPressed: load,
                  child: const Text('Tải lại khu vực'),
                ),
            ],
            if (token != null) ...[
              const SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    Text(
                      type == 'CHECK_IN' ? 'QR VÀO CA' : 'QR RA CA',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    if (remaining > 0)
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(8),
                        child: QrImageView(data: token!, size: 200),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Icon(
                          Icons.timer_off_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                      ),
                    Text(
                      remaining > 0
                          ? 'Còn ${remaining ~/ 60}:${(remaining % 60).toString().padLeft(2, '0')}'
                          : 'Mã đã hết hạn. Hãy tạo mã mới.',
                      style: TextStyle(
                        color: remaining > 0 ? Colors.teal : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Thử trên cùng máy: sao chép mã, mở tài khoản nhân viên ở cửa sổ khác và chọn nhập mã thủ công.',
                      style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: remaining == 0
                          ? null
                          : () async {
                              await Clipboard.setData(
                                ClipboardData(text: token!),
                              );
                              if (context.mounted)
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Đã sao chép mã QR.'),
                                  ),
                                );
                            },
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text('Sao chép mã'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Đóng'),
      ),
      FilledButton.icon(
        onPressed: loading || busy || areaId == null ? null : generate,
        icon: busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.qr_code_rounded, size: 18),
        label: Text(
          busy
              ? 'Đang tạo...'
              : token == null
              ? 'Tạo mã QR'
              : 'Tạo mã mới',
        ),
      ),
    ],
  );
}
