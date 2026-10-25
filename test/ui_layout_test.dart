import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:supermarket_hrm/core/theme/app_theme.dart';
import 'package:supermarket_hrm/features/auth/data/auth_repository.dart';
import 'package:supermarket_hrm/features/auth/presentation/auth_controller.dart';
import 'package:supermarket_hrm/features/auth/presentation/login_screen.dart';
import 'package:supermarket_hrm/features/launcher/feature_launcher_screen.dart';
import 'package:supermarket_hrm/features/management/manager_main_screen.dart';
import 'package:supermarket_hrm/features/reports/reports_main_screen.dart';
import 'package:supermarket_hrm/services/mock_data_service.dart';

void resize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Widget app(Widget home) => ChangeNotifierProvider(
  create: (_) => MockDataService()..setCurrentRole('ADMIN'),
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: AppTheme.lightTheme,
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    supportedLocales: const [Locale('vi', 'VN'), Locale('en', 'US')],
    home: home,
  ),
);

void main() {
  setUpAll(() => initializeDateFormatting('vi'));
  for (final width in [320.0, 1440.0]) {
    testWidgets('Home remains usable at width $width', (tester) async {
      resize(tester, Size(width, 900));
      await tester.pumpWidget(app(const FeatureLauncherScreen()));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Ứng dụng nhân viên'));
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Vai trò trải nghiệm'));
      await tester.tap(find.widgetWithText(ChoiceChip, 'Nhân sự'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
  for (final index in [1, 2, 3, 4, 6]) {
    testWidgets('Management section $index fits a phone', (tester) async {
      resize(tester, const Size(360, 844));
      await tester.pumpWidget(app(ManagerMainScreen(initialIndex: index)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('Manager mobile More menu includes approval', (tester) async {
    resize(tester, const Size(360, 844));
    await tester.pumpWidget(app(const ManagerMainScreen()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Thêm'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ListTile, 'Phê duyệt'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      4,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('Desktop manager exposes all sections', (tester) async {
    resize(tester, const Size(1440, 900));
    await tester.pumpWidget(app(const ManagerMainScreen(initialIndex: 2)));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsNothing);
    await tester.tap(find.widgetWithText(ListTile, 'Phê duyệt'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('All report tabs fit a phone', (tester) async {
    resize(tester, const Size(390, 844));
    await tester.pumpWidget(app(const ReportsMainScreen()));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    for (final label in [
      'Theo nhân viên',
      'Đi muộn / Vắng',
      'Lịch sử chi tiết',
      'Xuất báo cáo',
    ]) {
      await tester.ensureVisible(find.widgetWithText(Tab, label));
      await tester.tap(find.widgetWithText(Tab, label));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: label);
    }
    expect(
      find.text('Bao gồm tọa độ GPS & độ chính xác Geofence'),
      findsOneWidget,
    );
  });
  testWidgets('Login scrolls and validates on a small phone', (tester) async {
    resize(tester, const Size(320, 568));
    await tester.pumpWidget(
      app(
        ChangeNotifierProvider(
          create: (_) => AuthController(authRepository: AuthRepository()),
          child: const LoginScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
    await tester.pumpAndSettle();
    expect(find.text('Vui lòng nhập tài khoản'), findsOneWidget);
    expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
