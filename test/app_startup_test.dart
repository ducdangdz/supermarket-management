import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:supermarket_hrm/main.dart';
import 'package:supermarket_hrm/services/mock_data_service.dart';

void main() {
  testWidgets('App starts at login without exposing modules', (tester) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ChangeNotifierProvider(
      create: (_) => MockDataService(),
      child: const SmartMarketHrmApp(),
    ));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilledButton, 'Đăng nhập'), findsOneWidget);
    expect(find.text('Ứng dụng nhân viên'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
