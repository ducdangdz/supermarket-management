import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'attendance_controller.dart';
import 'models/attendance_models.dart';
import 'widgets/attendance_flow_view.dart';

/// Màn hình check-out: dùng chung luồng với check-in nhưng QR loại CHECK_OUT
/// và bị chặn nếu ca làm chưa check-in.
class CheckOutPage extends StatelessWidget {
  const CheckOutPage({super.key, this.controller});

  final AttendanceController? controller;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => (controller ?? AttendanceController(action: AttendanceAction.checkOut))..initialize(),
      child: const AttendanceFlowView(),
    );
  }
}
