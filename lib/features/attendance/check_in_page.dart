import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'attendance_controller.dart';
import 'models/attendance_models.dart';
import 'widgets/attendance_flow_view.dart';

/// Màn hình check-in: quét QR → GPS → ảnh bằng chứng (nếu ca yêu cầu) → gửi.
/// Pop với `true` khi check-in thành công để màn hình trước tải lại dữ liệu.
class CheckInPage extends StatelessWidget {
  const CheckInPage({super.key, this.controller});

  /// Cho phép truyền controller dựng sẵn (dùng trong widget test với service giả).
  final AttendanceController? controller;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          (controller ?? AttendanceController(action: AttendanceAction.checkIn))
            ..initialize(),
      child: const AttendanceFlowView(),
    );
  }
}
