import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/auth_controller.dart';

class EmployeeApp extends StatefulWidget {
  const EmployeeApp({super.key});

  @override
  State<EmployeeApp> createState() => _EmployeeAppState();
}

class _EmployeeAppState extends State<EmployeeApp> {
  late final AuthRepository _authRepository;
  late final AuthController _authController;

  @override
  void initState() {
    super.initState();
    _authRepository = AuthRepository();
    _authController = AuthController(authRepository: _authRepository)..checkAuth();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authController),
      ],
      child: Builder(
        builder: (context) {
          final auth = context.watch<AuthController>();
          final router = AppRouter.createRouter(auth);

          return MaterialApp.router(
            debugShowCheckedModeBanner: false,
            title: 'Supermarket HRM Employee',
            theme: AppTheme.lightTheme,
            routerConfig: router,
          );
        },
      ),
    );
  }
}
