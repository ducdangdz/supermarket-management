import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'models/employee.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/auth_controller.dart';

class EmployeeApp extends StatefulWidget {
  const EmployeeApp({super.key, this.employee, this.onLogout});
  final Employee? employee;
  final Future<void> Function()? onLogout;

  @override
  State<EmployeeApp> createState() => _EmployeeAppState();
}

class _EmployeeAppState extends State<EmployeeApp> {
  late final AuthRepository _authRepository;
  late final AuthController _authController;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authRepository = AuthRepository();
    _authController = AuthController(
      authRepository: _authRepository,
      initialEmployee: widget.employee,
      onSessionLogout: widget.onLogout,
    );
    _router = AppRouter.createRouter(_authController);
    if (widget.employee == null) _authController.checkAuth();
  }

  @override
  void dispose() {
    _router.dispose();
    _authController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider.value(value: _authController)],
      child: Builder(
        builder: (context) {
          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'Supermarket HRM Employee',
            theme: AppTheme.lightTheme,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            supportedLocales: const [Locale('vi', 'VN'), Locale('en', 'US')],
            routerConfig: _router,
          );
        },
      ),
    );
  }
}
