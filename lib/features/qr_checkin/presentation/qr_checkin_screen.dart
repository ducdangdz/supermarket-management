import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/network/team_api.dart';
import '../../../core/theme/app_theme.dart';
import '../../backend/location/location_service.dart';

/// The team's scanner now submits to the same attendance API as the online workspace.
class QrCheckinScreen extends StatefulWidget {
  const QrCheckinScreen({super.key});
  @override
  State<QrCheckinScreen> createState() => _QrCheckinScreenState();
}

class _QrCheckinScreenState extends State<QrCheckinScreen> {
  final scanner = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  final text = TextEditingController();
  bool busy = false, done = false;
  String? error, message;
  @override
  void dispose() {
    scanner.dispose();
    text.dispose();
    super.dispose();
  }

  Future<void> submit(String token) async {
    if (busy || done || token.trim().isEmpty) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final api = TeamApi.active!;
      final day = TeamApi.day(DateTime.now());
      final schedules = (await api.schedules(from: day, to: day))
          .where(
            (s) =>
                s['scheduleStatus'] == 'SCHEDULED' && s['checkOutAt'] == null,
          )
          .toList();
      if (!mounted) return;
      if (schedules.isEmpty)
        throw StateError('Không có ca làm hôm nay đang chờ chấm công.');
      Map<String, dynamic>? schedule;
      if (schedules.length == 1) {
        schedule = schedules.single;
      } else {
        schedule = await showDialog<Map<String, dynamic>>(
          context: context,
          builder: (ctx) => SimpleDialog(
            title: const Text('Chọn ca cần chấm công'),
            children: [
              for (final s in schedules)
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, s),
                  child: Text(
                    '${s['shiftName']} · ${s['startTime']} · ${s['areaName']}',
                  ),
                ),
            ],
          ),
        );
        if (schedule == null) return;
      }
      LocationSample? location;
      try {
        location = await getCurrentLocation();
      } catch (_) {
        if (schedule['requireLocation'] == true)
          throw StateError(
            'Ca làm yêu cầu vị trí. Hãy cho phép truy cập vị trí rồi thử lại.',
          );
      }
      final checkout = schedule['checkInAt'] != null;
      final result = await api.request(
        '/attendance/${checkout ? 'check-out' : 'check-in'}',
        method: 'POST',
        body: {
          'scheduleId': schedule['scheduleId'],
          'employeeId': api.employeeId,
          'qrToken': token.trim(),
          'latitude': location?.latitude,
          'longitude': location?.longitude,
          'accuracyMeters': location?.accuracyMeters,
        },
      );
      if (mounted)
        setState(() {
          done = true;
          message =
              result['message']?.toString() ?? 'Đã lưu chấm công vào hệ thống.';
        });
      await scanner.stop();
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Quét QR chấm công'),
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => context.pop(done),
      ),
    ),
    body: done
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppTheme.success,
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(message ?? ''),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => context.pop(true),
                    child: const Text('Quay lại tổng quan'),
                  ),
                ],
              ),
            ),
          )
        : Column(
            children: [
              Expanded(
                child: MobileScanner(
                  controller: scanner,
                  onDetect: (capture) {
                    for (final code in capture.barcodes) {
                      if (code.rawValue != null) {
                        submit(code.rawValue!);
                        break;
                      }
                    }
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    if (error != null)
                      Text(error!, style: const TextStyle(color: Colors.red)),
                    if (busy) const LinearProgressIndicator(),
                    TextField(
                      controller: text,
                      enabled: !busy,
                      decoration: const InputDecoration(
                        labelText: 'Hoặc nhập mã QR do quản lý cấp',
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: busy ? null : () => submit(text.text),
                      child: const Text('Xác nhận chấm công'),
                    ),
                  ],
                ),
              ),
            ],
          ),
  );
}
