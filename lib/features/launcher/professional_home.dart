import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_brand.dart';
import '../../models/employee.dart';
import '../../services/mock_data_service.dart';

class ProfessionalHome extends StatefulWidget {
  const ProfessionalHome({
    super.key,
    required this.employee,
    required this.roleCode,
    required this.data,
    required this.onEmployee,
    required this.onManager,
    required this.onReports,
    required this.onLogout,
    required this.onRefresh,
    required this.updatedAt,
    this.refreshing = false,
    this.error,
  });
  final Employee employee;
  final String roleCode;
  final MockDataService data;
  final VoidCallback onEmployee, onReports;
  final ValueChanged<int> onManager;
  final Future<void> Function() onLogout, onRefresh;
  final DateTime updatedAt;
  final bool refreshing;
  final String? error;
  @override
  State<ProfessionalHome> createState() => _ProfessionalHomeState();
}

class _ProfessionalHomeState extends State<ProfessionalHome> {
  String query = '';
  bool signingOut = false;
  bool get staff => widget.roleCode != 'EMPLOYEE';
  String get role => switch (widget.roleCode) {
    'ADMIN' => 'Quản trị viên',
    'MANAGER' => 'Quản lý',
    'HR' => 'Nhân sự',
    _ => 'Nhân viên',
  };
  Future<void> logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Đăng xuất tài khoản?'),
        content: const Text('Bạn sẽ trở về màn hình đăng nhập.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Ở lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => signingOut = true);
    try {
      await widget.onLogout();
    } finally {
      if (mounted) setState(() => signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<MockDataService>();
    final modules =
        <
          ({
            String title,
            String description,
            IconData icon,
            Color color,
            String action,
            VoidCallback open,
          })
        >[
          (
            title: 'Ứng dụng nhân viên',
            description:
                'Lịch làm việc, chấm công QR và hồ sơ cá nhân của bạn.',
            icon: Icons.badge_outlined,
            color: AppColors.primary,
            action: 'Vào không gian nhân viên',
            open: widget.onEmployee,
          ),
          if (staff)
            (
              title: 'Quản lý vận hành',
              description:
                  'Quản lý đội ngũ, ca làm, lịch phân công và phê duyệt.',
              icon: Icons.space_dashboard_outlined,
              color: const Color(0xFF087F8C),
              action: 'Vào không gian quản lý',
              open: () => widget.onManager(0),
            ),
          if (staff)
            (
              title: 'Báo cáo & thống kê',
              description:
                  'Theo dõi chuyên cần, lịch sử chấm công và xuất dữ liệu.',
              icon: Icons.insights_outlined,
              color: const Color(0xFF7157B9),
              action: 'Mở trung tâm báo cáo',
              open: widget.onReports,
            ),
        ];
    final visible = modules
        .where(
          (m) => ('${m.title} ${m.description}').toLowerCase().contains(
            query.toLowerCase(),
          ),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 76,
        title: const AppBrand(),
        actions: [
          IconButton(
            tooltip: 'Làm mới dữ liệu',
            onPressed: widget.refreshing ? null : widget.onRefresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Đăng xuất',
            onPressed: signingOut ? null : logout,
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Padding(
                padding: EdgeInsets.all(
                  MediaQuery.sizeOf(context).width < 600 ? 16 : 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.refreshing) const LinearProgressIndicator(),
                    if (widget.error != null) ...[
                      _notice(
                        Icons.cloud_off_outlined,
                        widget.error!,
                        error: true,
                      ),
                      const SizedBox(height: 16),
                    ],
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Không gian làm việc',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat(
                                'EEEE, dd/MM/yyyy',
                                'vi',
                              ).format(DateTime.now()),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        Chip(
                          avatar: const Icon(
                            Icons.verified_user_outlined,
                            size: 16,
                          ),
                          label: Text(role),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF103654), Color(0xFF176280)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: LayoutBuilder(
                        builder: (context, c) {
                          final text = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'SMARTMARKET · HUMAN RESOURCES',
                                style: TextStyle(
                                  color: Color(0xFF9BE2D8),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'Xin chào, ${widget.employee.name}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  height: 1.3,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                widget.employee.branch,
                                style: const TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${widget.employee.employeeCode} · ${widget.employee.email}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 20),
                              FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.primary,
                                ),
                                onPressed: staff
                                    ? () => widget.onManager(0)
                                    : widget.onEmployee,
                                icon: const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 18,
                                ),
                                label: Text(
                                  staff
                                      ? 'Mở bảng điều hành'
                                      : 'Xem lịch làm của tôi',
                                ),
                              ),
                            ],
                          );
                          if (c.maxWidth < 750) return text;
                          return Row(
                            children: [
                              Expanded(child: text),
                              const SizedBox(width: 32),
                              Container(
                                width: 220,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: .08),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: .12),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(
                                      Icons.fact_check_outlined,
                                      color: Color(0xFF9BE2D8),
                                      size: 30,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      staff
                                          ? '${data.pendingApprovalCount}'
                                          : 'Hôm nay',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 30,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      staff
                                          ? 'Bản ghi đang chờ phê duyệt'
                                          : 'Lịch làm và chấm công cá nhân',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    if (widget.employee.branch ==
                        'Chưa được gán chi nhánh') ...[
                      const SizedBox(height: 16),
                      _notice(
                        Icons.info_outline,
                        'Tài khoản chưa được gán chi nhánh. Liên hệ quản trị viên để được phân công ca làm.',
                      ),
                    ],
                    if (staff) ...[
                      const SizedBox(height: 24),
                      LayoutBuilder(
                        builder: (context, c) {
                          final cols = c.maxWidth > 850 ? 4 : 2;
                          final items = [
                            (
                              'Nhân viên hoạt động',
                              '${data.activeEmployeesCount}',
                              Icons.people_outline,
                              AppColors.primary,
                            ),
                            (
                              'Lịch làm hôm nay',
                              '${data.todayScheduledCount}',
                              Icons.calendar_month_outlined,
                              const Color(0xFF087F8C),
                            ),
                            (
                              'Đã vào ca',
                              '${data.todayCheckedInCount}',
                              Icons.login_rounded,
                              AppColors.secondary,
                            ),
                            (
                              'Chờ phê duyệt',
                              '${data.pendingApprovalCount}',
                              Icons.pending_actions_rounded,
                              const Color(0xFFC27A13),
                            ),
                          ];
                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              for (final (label, value, icon, color) in items)
                                SizedBox(
                                  width: (c.maxWidth - (cols - 1) * 12) / cols,
                                  child: Card(
                                    margin: EdgeInsets.zero,
                                    child: Padding(
                                      padding: const EdgeInsets.all(18),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Icon(icon, color: color, size: 22),
                                          const SizedBox(height: 14),
                                          Text(
                                            value,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.headlineMedium,
                                          ),
                                          Text(
                                            label,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                    const SizedBox(height: 30),
                    Text(
                      'Chức năng của bạn',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Truy cập các nghiệp vụ được cấp cho tài khoản.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      onChanged: (v) => setState(() => query = v.trim()),
                      decoration: const InputDecoration(
                        hintText: 'Tìm chức năng theo tên hoặc công việc...',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (visible.isEmpty)
                      _notice(
                        Icons.search_off_rounded,
                        'Không tìm thấy chức năng phù hợp. Thử từ khóa khác.',
                      ),
                    LayoutBuilder(
                      builder: (context, c) {
                        final cols = c.maxWidth >= 1000
                            ? 3
                            : c.maxWidth >= 620
                            ? 2
                            : 1;
                        return Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            for (final m in visible)
                              SizedBox(
                                width: (c.maxWidth - (cols - 1) * 16) / cols,
                                child: Card(
                                  margin: EdgeInsets.zero,
                                  clipBehavior: Clip.antiAlias,
                                  child: InkWell(
                                    onTap: m.open,
                                    child: Padding(
                                      padding: const EdgeInsets.all(22),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: m.color.withValues(
                                                alpha: .09,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              m.icon,
                                              color: m.color,
                                              size: 26,
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          Text(
                                            m.title,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleMedium,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            m.description,
                                            style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 13,
                                              height: 1.6,
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          const Divider(),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  m.action,
                                                  style: TextStyle(
                                                    color: m.color,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                              ),
                                              Icon(
                                                Icons.arrow_forward_rounded,
                                                color: m.color,
                                                size: 18,
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 28),
                    if (staff) ...[
                      Text(
                        'Công việc cần xử lý',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 14),
                      Card(
                        margin: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _task(
                              Icons.fact_check_outlined,
                              'Duyệt chấm công',
                              '${data.pendingApprovalCount} bản ghi đang chờ xem xét',
                              () => widget.onManager(6),
                            ),
                            const Divider(height: 1, indent: 68),
                            _task(
                              Icons.calendar_month_outlined,
                              'Xếp lịch làm việc',
                              'Kiểm tra ca làm, nhân sự và vị trí phân công',
                              () => widget.onManager(4),
                            ),
                            const Divider(height: 1, indent: 68),
                            _task(
                              Icons.insights_outlined,
                              'Theo dõi chuyên cần',
                              'Đọc báo cáo và xuất dữ liệu chấm công',
                              widget.onReports,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],
                    Row(
                      children: [
                        const Icon(
                          Icons.sync_rounded,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Cập nhật lúc ${DateFormat('HH:mm:ss').format(widget.updatedAt)} · Dữ liệu hệ thống',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _task(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback open,
  ) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
    leading: Icon(icon, color: AppColors.primary),
    title: Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
    ),
    subtitle: Text(
      subtitle,
      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
    ),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: open,
  );
  Widget _notice(IconData icon, String text, {bool error = false}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: error ? const Color(0xFFFEF2F2) : const Color(0xFFFFF8E8),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: error ? const Color(0xFFFECACA) : const Color(0xFFF4DFAC),
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: error ? Colors.red : const Color(0xFF9B6A14),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 13, height: 1.5)),
        ),
      ],
    ),
  );
}
