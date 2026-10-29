import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supermarket_hrm/features/backend/backend_workspace.dart';

void main() {
  testWidgets('Backend login displays progress and invokes Google login', (
    tester,
  ) async {
    var loginRequests = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(
          initializing: true,
          onAuthenticated: (_) {},
          loading: false,
          error: null,
          onNativeLogin: () async {
            loginRequests++;
          },
        ),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpWidget(
      MaterialApp(
        home: LoginPage(
          initializing: false,
          onAuthenticated: (_) {},
          loading: false,
          error: 'Không kết nối được hệ thống',
          onNativeLogin: () async {
            loginRequests++;
          },
        ),
      ),
    );
    expect(find.widgetWithText(FilledButton, 'Đăng nhập'), findsOneWidget);
    expect(find.text('Google: Không kết nối được hệ thống'), findsOneWidget);
    await tester.ensureVisible(find.text('Đăng nhập với Google'));
    await tester.tap(find.text('Đăng nhập với Google'));
    expect(loginRequests, 1);
  });
}
