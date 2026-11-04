import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supermarket_hrm/core/services/storage_service.dart';
import 'package:supermarket_hrm/features/auth/presentation/account_access_screen.dart';
import 'package:supermarket_hrm/features/launcher/feature_launcher_screen.dart';
import 'package:supermarket_hrm/services/mock_data_service.dart';

void main() {
  testWidgets(
    'Employee flow can be opened, closed and reopened from launcher',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      SharedPreferences.setMockInitialValues({});
      await StorageService.init();
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => MockDataService(),
          child: const MaterialApp(home: FeatureLauncherScreen()),
        ),
      );
      for (var attempt = 0; attempt < 2; attempt++) {
        await tester.ensureVisible(find.text('Ứng dụng nhân viên'));
        await tester.tap(find.text('Ứng dụng nhân viên'));
        await tester.pumpAndSettle();
        expect(find.byType(AccountAccessScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.byType(BackButton).first);
        await tester.pumpAndSettle();
        expect(find.byType(FeatureLauncherScreen), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    },
  );
}
