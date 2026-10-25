import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app.dart';
import '../../core/network/team_api.dart';
import '../../models/employee.dart';
import '../../services/mock_data_service.dart';
import '../backend/backend_workspace.dart';
import 'professional_home.dart';
import '../management/manager_main_screen.dart';
import '../reports/reports_main_screen.dart';

class AuthenticatedTeamHome extends StatefulWidget {
  const AuthenticatedTeamHome({
    super.key,
    required this.session,
    required this.onLogout,
    this.api,
  });
  final TeamApi? api;
  final Session session;
  final Future<void> Function() onLogout;
  @override
  State<AuthenticatedTeamHome> createState() => _AuthenticatedTeamHomeState();
}

class _AuthenticatedTeamHomeState extends State<AuthenticatedTeamHome> {
  late final TeamApi api;
  late final MockDataService data;
  late Future<void> loading;
  Employee? employee;
  DateTime updatedAt = DateTime.now();
  bool refreshing = false;
  String? refreshError;
  Future<void> refresh() async {
    if (refreshing) return;
    setState(() {
      refreshing = true;
      refreshError = null;
    });
    try {
      await load();
    } catch (e) {
      if (mounted) setState(() => refreshError = e.toString());
    } finally {
      if (mounted) setState(() => refreshing = false);
    }
  }

  void open(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ChangeNotifierProvider.value(value: data, child: screen),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    api =
        widget.api ??
        TeamApi(
          employeeId: widget.session.employeeId,
          token: widget.session.idToken,
        );
    TeamApi.active = api;
    data = MockDataService(
      remoteApi: api,
      sessionBranchId: widget.session.branchId,
      roleCode: widget.session.roleCode,
    );
    loading = load();
  }

  Future<void> load() async {
    employee = await api.profile();
    if (widget.session.roleCode != 'EMPLOYEE') await data.refresh();
    updatedAt = DateTime.now();
  }

  Future<void> logout() async {
    Navigator.of(context).popUntil((r) => r.isFirst);
    await widget.onLogout();
  }

  @override
  void dispose() {
    api.close();
    data.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider.value(
    value: data,
    child: FutureBuilder<void>(
      future: loading,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done)
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        if (snapshot.hasError)
          return Scaffold(
            appBar: AppBar(
              title: const Text('Kết nối dữ liệu'),
              actions: [
                TextButton(onPressed: logout, child: const Text('Đăng xuất')),
              ],
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off_rounded,
                      size: 48,
                      color: Colors.blueGrey,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Chưa thể tải không gian làm việc',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Text(
                        snapshot.error.toString(),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => setState(() => loading = load()),
                      child: const Text('Thử lại'),
                    ),
                  ],
                ),
              ),
            ),
          );
        return ProfessionalHome(
          employee: employee!,
          roleCode: widget.session.roleCode,
          data: data,
          updatedAt: updatedAt,
          refreshing: refreshing,
          error: refreshError,
          onLogout: logout,
          onRefresh: refresh,
          onManager: (index) => open(ManagerMainScreen(initialIndex: index)),
          onReports: () => open(const ReportsMainScreen()),
          onEmployee: () =>
              open(EmployeeApp(employee: employee, onLogout: logout)),
        );
      },
    ),
  );
}
