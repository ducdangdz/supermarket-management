import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../attendance_controller.dart';
import '../attendance_result_page.dart';
import '../data/mock_attendance_repository.dart';
import '../evidence_capture_page.dart';
import '../models/attendance_models.dart';
import '../qr_scanner_page.dart';
import '../services/location_service.dart';

/// Giao diện chung cho check-in và check-out (đọc state từ [AttendanceController] qua Provider).
/// Gồm 3 bước: quét QR → vị trí GPS → ảnh bằng chứng, rồi nút "Hoàn tất".
class AttendanceFlowView extends StatelessWidget {
  const AttendanceFlowView({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = context.watch<AttendanceController>();
    final action = ctrl.action;
    final schedule = ctrl.selectedSchedule;
    final blocked = ctrl.scheduleViolation;

    return Scaffold(
      appBar: AppBar(
        title: Text('${action.label} ca làm'),
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            icon: const Icon(Icons.refresh),
            onPressed: ctrl.isSubmitting ? null : ctrl.initialize,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _ScheduleSection(ctrl: ctrl),
          if (blocked != null) ...[
            const SizedBox(height: 12),
            _Banner(
              icon: Icons.block,
              color: AppTheme.error,
              text: blocked.message,
            ),
          ],
          if (schedule != null && blocked == null) ...[
            const SizedBox(height: 16),
            _QrStep(ctrl: ctrl),
            const SizedBox(height: 12),
            _LocationStep(ctrl: ctrl),
            const SizedBox(height: 12),
            _EvidenceStep(ctrl: ctrl),
          ],
          if (ctrl.repository is MockAttendanceRepository) ...[
            const SizedBox(height: 16),
            _MockScenarioPanel(ctrl: ctrl),
          ],
        ],
      ),
      bottomNavigationBar: _SubmitBar(ctrl: ctrl),
    );
  }
}

// ─── Ca làm ───────────────────────────────────────────────────────────────────

class _ScheduleSection extends StatelessWidget {
  const _ScheduleSection({required this.ctrl});

  final AttendanceController ctrl;

  @override
  Widget build(BuildContext context) {
    if (ctrl.isLoadingSchedules) {
      return const Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Text('Đang tải lịch làm hôm nay...'),
            ],
          ),
        ),
      );
    }
    if (ctrl.scheduleError != null) {
      return _Banner(
        icon: Icons.cloud_off,
        color: AppTheme.error,
        text: ctrl.scheduleError!,
        action: TextButton(
          onPressed: ctrl.loadSchedules,
          child: const Text('Thử lại'),
        ),
      );
    }
    final schedule = ctrl.selectedSchedule;
    if (schedule == null) return const SizedBox.shrink();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (ctrl.schedules.length > 1) ...[
              DropdownButtonFormField<int>(
                initialValue: schedule.scheduleId,
                decoration: const InputDecoration(labelText: 'Chọn ca làm'),
                items: ctrl.schedules
                    .map(
                      (s) => DropdownMenuItem(
                        value: s.scheduleId,
                        child: Text(
                          '${s.shiftName} · ${s.startTime}-${s.endTime}',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (id) => ctrl.selectSchedule(
                  ctrl.schedules.firstWhere((s) => s.scheduleId == id),
                ),
              ),
              const SizedBox(height: 12),
            ],
            Text(
              schedule.shiftName,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            _iconText(
              Icons.schedule,
              '${schedule.startTime} - ${schedule.endTime} · cho phép trễ ${schedule.allowedLateMinutes} phút',
            ),
            const SizedBox(height: 4),
            _iconText(
              Icons.place_outlined,
              schedule.floorName == null
                  ? schedule.areaName
                  : '${schedule.areaName} · ${schedule.floorName}',
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _requirementChip('QR', schedule.requireQr),
                _requirementChip('GPS', schedule.requireLocation),
                _requirementChip('Ảnh bằng chứng', schedule.requireEvidence),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconText(IconData icon, String text) => Row(
    children: [
      Icon(icon, size: 16, color: AppTheme.textSecondary),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
      ),
    ],
  );

  Widget _requirementChip(String label, bool required) => Chip(
    visualDensity: VisualDensity.compact,
    avatar: Icon(
      required ? Icons.check_circle : Icons.remove_circle_outline,
      size: 16,
      color: required ? AppTheme.primary : AppTheme.textHint,
    ),
    label: Text(
      '$label: ${required ? 'bắt buộc' : 'không bắt buộc'}',
      style: const TextStyle(fontSize: 12),
    ),
  );
}

// ─── Bước 1: QR ───────────────────────────────────────────────────────────────

class _QrStep extends StatelessWidget {
  const _QrStep({required this.ctrl});

  final AttendanceController ctrl;

  Future<void> _scan(BuildContext context) async {
    final token = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => QrScannerPage(action: ctrl.action)),
    );
    if (token != null) ctrl.setQrToken(token);
  }

  @override
  Widget build(BuildContext context) {
    final token = ctrl.qrToken;
    return _StepCard(
      index: 1,
      title: 'Quét mã QR',
      done: token != null,
      required: ctrl.selectedSchedule?.requireQr ?? true,
      child: token == null
          ? ElevatedButton.icon(
              onPressed: () => _scan(context),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Mở camera quét QR'),
            )
          : Row(
              children: [
                Expanded(
                  child: Text(
                    'Đã quét: ${_mask(token)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.success,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _scan(context),
                  child: const Text('Quét lại'),
                ),
              ],
            ),
    );
  }

  /// Không hiển thị toàn bộ token để tránh bị chụp màn hình chia sẻ.
  static String _mask(String token) => token.length <= 10
      ? token
      : '${token.substring(0, 6)}…${token.substring(token.length - 4)}';
}

// ─── Bước 2: GPS ──────────────────────────────────────────────────────────────

class _LocationStep extends StatelessWidget {
  const _LocationStep({required this.ctrl});

  final AttendanceController ctrl;

  @override
  Widget build(BuildContext context) {
    final result = ctrl.locationResult;
    final location = result?.location;
    final required = ctrl.selectedSchedule?.requireLocation ?? false;

    Widget content;
    if (ctrl.isLocating) {
      content = const Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 10),
          Text('Đang lấy vị trí GPS...'),
        ],
      );
    } else if (location != null) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Vĩ độ: ${location.latitude.toStringAsFixed(6)}'),
          Text('Kinh độ: ${location.longitude.toStringAsFixed(6)}'),
          Text('Sai số: ±${location.accuracyMeters.toStringAsFixed(0)} m'),
          if (location.isMocked)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                '⚠ Thiết bị đang dùng vị trí giả lập, thông tin này sẽ được gửi kèm.',
                style: TextStyle(color: AppTheme.warning, fontSize: 12),
              ),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: ctrl.fetchLocation,
              icon: const Icon(Icons.my_location, size: 18),
              label: const Text('Lấy lại vị trí'),
            ),
          ),
        ],
      );
    } else {
      final failure = result?.failure;
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Banner(
            icon:
                failure == LocationFailure.permissionDenied ||
                    failure == LocationFailure.permissionDeniedForever
                ? Icons.location_disabled
                : Icons.gps_off,
            color: required ? AppTheme.error : AppTheme.warning,
            text:
                '${result?.message ?? 'Chưa có vị trí.'}'
                '${required ? '' : '\nCa này không bắt buộc GPS nên vẫn có thể tiếp tục.'}',
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: ctrl.fetchLocation,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Thử lại'),
              ),
              if (failure == LocationFailure.permissionDeniedForever)
                OutlinedButton.icon(
                  onPressed: ctrl.locationService.openAppSettings,
                  icon: const Icon(Icons.settings, size: 18),
                  label: const Text('Mở cài đặt ứng dụng'),
                ),
              if (failure == LocationFailure.serviceDisabled)
                OutlinedButton.icon(
                  onPressed: ctrl.locationService.openLocationSettings,
                  icon: const Icon(Icons.settings, size: 18),
                  label: const Text('Bật GPS'),
                ),
            ],
          ),
        ],
      );
    }

    return _StepCard(
      index: 2,
      title: 'Vị trí GPS',
      done: location != null,
      required: required,
      child: content,
    );
  }
}

// ─── Bước 3: Ảnh bằng chứng ───────────────────────────────────────────────────

class _EvidenceStep extends StatelessWidget {
  const _EvidenceStep({required this.ctrl});

  final AttendanceController ctrl;

  Future<void> _capture(BuildContext context) async {
    final photo = await Navigator.of(context).push<EvidencePhoto>(
      MaterialPageRoute(
        builder: (_) => EvidenceCapturePage(action: ctrl.action),
      ),
    );
    if (photo != null) ctrl.setEvidence(photo);
  }

  @override
  Widget build(BuildContext context) {
    final photo = ctrl.evidence;
    final required = ctrl.selectedSchedule?.requireEvidence ?? false;
    return _StepCard(
      index: 3,
      title: 'Ảnh bằng chứng',
      done: photo != null,
      required: required,
      child: photo == null
          ? OutlinedButton.icon(
              onPressed: () => _capture(context),
              icon: const Icon(Icons.photo_camera_outlined),
              label: Text(
                required ? 'Chụp ảnh (bắt buộc)' : 'Chụp ảnh (tùy chọn)',
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
              ),
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(
                    photo.bytes,
                    width: 96,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Đã chụp ảnh',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.success,
                        ),
                      ),
                      Text(
                        'Lúc ${photo.capturedAt.hour.toString().padLeft(2, '0')}:'
                        '${photo.capturedAt.minute.toString().padLeft(2, '0')} · '
                        '${(photo.bytes.length / 1024).toStringAsFixed(0)} KB',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      TextButton(
                        onPressed: () => _capture(context),
                        child: const Text('Chụp lại'),
                      ),
                      TextButton(
                        onPressed: () => ctrl.setEvidence(null),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.error,
                        ),
                        child: const Text('Xóa ảnh'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

// ─── Nút hoàn tất ─────────────────────────────────────────────────────────────

class _SubmitBar extends StatelessWidget {
  const _SubmitBar({required this.ctrl});

  final AttendanceController ctrl;

  Future<void> _submit(BuildContext context) async {
    final navigator = Navigator.of(context);
    final result = await ctrl.submit();
    final choice = await navigator.push<AttendanceResultChoice>(
      MaterialPageRoute(builder: (_) => AttendanceResultPage(result: result)),
    );
    // Thành công hoặc chọn "Về trang chủ" → đóng luồng, báo màn hình trước tải lại dữ liệu.
    if (result.success || choice == AttendanceResultChoice.home) {
      if (navigator.canPop()) {
        navigator.pop(result.success);
      } else if (context.mounted) {
        // Mở trực tiếp bằng URL (deep link / tải lại trang web) → không có màn hình phía dưới để quay về.
        GoRouter.maybeOf(context)?.go('/dashboard');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = ctrl.pendingViolation;
    final showHint =
        pending != null &&
        ctrl.scheduleViolation == null &&
        !ctrl.isLoadingSchedules;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showHint)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  pending.message,
                  key: const Key('attendance-pending-hint'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ElevatedButton.icon(
              key: const Key('attendance-submit'),
              onPressed: ctrl.canSubmit ? () => _submit(context) : null,
              icon: ctrl.isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      ctrl.action == AttendanceAction.checkIn
                          ? Icons.login
                          : Icons.logout,
                    ),
              label: Text(
                ctrl.isSubmitting
                    ? 'Đang gửi...'
                    : 'Hoàn tất ${ctrl.action.label.toLowerCase()}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Panel demo (chỉ hiện khi chạy mock) ──────────────────────────────────────

class _MockScenarioPanel extends StatefulWidget {
  const _MockScenarioPanel({required this.ctrl});

  final AttendanceController ctrl;

  @override
  State<_MockScenarioPanel> createState() => _MockScenarioPanelState();
}

class _MockScenarioPanelState extends State<_MockScenarioPanel> {
  MockAttendanceScenario get _scenario =>
      (widget.ctrl.repository as MockAttendanceRepository).scenario;

  void _update(VoidCallback change) {
    setState(change);
    widget.ctrl.loadSchedules();
  }

  @override
  Widget build(BuildContext context) {
    final s = _scenario;
    return Card(
      margin: EdgeInsets.zero,
      color: const Color(0xFFFFF8E1),
      child: ExpansionTile(
        leading: const Icon(Icons.science_outlined, color: AppTheme.warning),
        title: const Text(
          'Chế độ demo (không có backend)',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        subtitle: const Text(
          'Giả lập các business rule',
          style: TextStyle(fontSize: 12),
        ),
        children: [
          SwitchListTile(
            dense: true,
            title: const Text('Không có lịch làm hôm nay'),
            value: s.noScheduleToday,
            onChanged: (v) => _update(() => s.noScheduleToday = v),
          ),
          SwitchListTile(
            dense: true,
            title: const Text('Ca yêu cầu ảnh bằng chứng'),
            value: s.requireEvidence,
            onChanged: (v) => _update(() => s.requireEvidence = v),
          ),
          SwitchListTile(
            dense: true,
            title: const Text('Ca yêu cầu GPS'),
            value: s.requireLocation,
            onChanged: (v) => _update(() => s.requireLocation = v),
          ),
          SwitchListTile(
            dense: true,
            title: const Text('GPS ở ngoài bán kính khu vực'),
            value: s.outsideRadius,
            onChanged: (v) => _update(() => s.outsideRadius = v),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: SegmentedButton<SimulatedClock>(
              segments: const [
                ButtonSegment(
                  value: SimulatedClock.onTime,
                  label: Text('Đúng giờ'),
                ),
                ButtonSegment(
                  value: SimulatedClock.late,
                  label: Text('Đi muộn'),
                ),
                ButtonSegment(
                  value: SimulatedClock.real,
                  label: Text('Giờ thực'),
                ),
              ],
              selected: {s.clock},
              onSelectionChanged: (v) => setState(() => s.clock = v.first),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Widget phụ ───────────────────────────────────────────────────────────────

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.index,
    required this.title,
    required this.done,
    required this.required,
    required this.child,
  });

  final int index;
  final String title;
  final bool done;
  final bool required;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 13,
                  backgroundColor: done
                      ? AppTheme.success
                      : AppTheme.primary.withValues(alpha: 0.12),
                  child: done
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : Text(
                          '$index',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.primary,
                          ),
                        ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  required ? 'Bắt buộc' : 'Tùy chọn',
                  style: TextStyle(
                    fontSize: 12,
                    color: required ? AppTheme.error : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.color,
    required this.text,
    this.action,
  });

  final IconData icon;
  final Color color;
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}
