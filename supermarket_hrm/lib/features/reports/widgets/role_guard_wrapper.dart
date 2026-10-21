import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/mock_data_service.dart';

/// Widget kiểm tra quyền truy cập theo vai trò (Role-Based Access Control)
class RoleGuardWrapper extends StatelessWidget {
  final List<String> allowedRoles;
  final Widget child;
  final String screenTitle;

  const RoleGuardWrapper({
    super.key,
    required this.allowedRoles,
    required this.child,
    this.screenTitle = 'Báo cáo',
  });

  @override
  Widget build(BuildContext context) {
    final data = context.watch<MockDataService>();
    final currentRole = data.currentRoleCode;

    if (allowedRoles.contains(currentRole)) {
      return child;
    }

    // Giao diện khi bị chặn quyền truy cập (Dành cho EMPLOYEE khi vào màn của ADMIN/MANAGER/HR)
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.gpp_bad_rounded, size: 64, color: Colors.red.shade600),
              ),
              const SizedBox(height: 20),
              const Text(
                'Truy cập bị giới hạn',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Màn hình "$screenTitle" chỉ dành riêng cho các vai trò:\n${allowedRoles.join(" • ")}.\n\nBạn đang truy cập với vai trò: $currentRole.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBAE6FD)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: Color(0xFF0284C7), size: 22),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '💡 Gợi ý: Với vai trò EMPLOYEE, bạn có thể xem lịch sử cá nhân tại "Màn 4: Lịch sử chấm công chi tiết".',
                        style: TextStyle(fontSize: 12, color: Color(0xFF0369A1)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
