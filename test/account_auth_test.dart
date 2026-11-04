import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supermarket_hrm/core/theme/app_theme.dart';
import 'package:supermarket_hrm/features/auth/data/account_auth_api.dart';
import 'package:supermarket_hrm/features/auth/presentation/account_access_screen.dart';

const challenge = '8acf1170-a88f-4e32-9d2c-b63f7abdc891';
const loginResponse = {
  'token': 'smh_test_token',
  'user': {
    'employeeId': 42,
    'fullName': 'Nhân viên mới',
    'email': 'new@example.com',
    'roleCode': 'EMPLOYEE',
    'roleName': 'Nhân viên',
  },
};
http.Response jsonResponse(Object data, [int status = 200]) => http.Response(
  jsonEncode(data),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);

Future<void> openScreen(
  WidgetTester tester,
  AccountAuthApi api,
  ValueChanged<AccountSession> accepted,
) async {
  tester.view.physicalSize = const Size(390, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      home: AccountAccessScreen(api: api, onAuthenticated: accepted),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> click(WidgetTester tester, String label) async {
  final target = find.text(label).last;
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

void main() {
  test(
    'Credential API preserves password whitespace and reads real session',
    () async {
      final api = AccountAuthApi(
        baseUrl: 'http://test/api',
        client: MockClient((request) async {
          expect(request.url.path, '/api/auth/login');
          expect(jsonDecode(request.body), {
            'username': 'new@example.com',
            'password': ' Password123! ',
          });
          return jsonResponse(loginResponse);
        }),
      );
      addTearDown(api.close);
      final session = await api.login('  new@example.com ', ' Password123! ');
      expect(session.user['employeeId'], 42);
      expect(session.token, 'smh_test_token');
    },
  );
  test(
    'An invalid login stays an error and never falls back to sample identity',
    () async {
      final api = AccountAuthApi(
        baseUrl: 'http://test/api',
        client: MockClient(
          (_) async =>
              jsonResponse({'message': 'Sai thông tin đăng nhập'}, 401),
        ),
      );
      addTearDown(api.close);
      await expectLater(
        api.login('employee', '123456'),
        throwsA(
          isA<AccountApiException>().having(
            (e) => e.message,
            'message',
            'Sai thông tin đăng nhập',
          ),
        ),
      );
    },
  );
  test(
    'Malformed successful response is not treated as a signed-in account',
    () async {
      final api = AccountAuthApi(
        baseUrl: 'http://test/api',
        client: MockClient((_) async => jsonResponse({})),
      );
      addTearDown(api.close);
      await expectLater(
        api.login('new@example.com', 'Password123!'),
        throwsA(isA<AccountApiException>()),
      );
    },
  );
  test('Logout sends session authorization', () async {
    final api = AccountAuthApi(
      baseUrl: 'http://test/api',
      client: MockClient((request) async {
        expect(request.url.path, '/api/auth/logout');
        expect(request.headers['Authorization'], 'Bearer smh_test_token');
        return jsonResponse({'message': 'signed out'});
      }),
    );
    addTearDown(api.close);
    await api.logout('smh_test_token');
  });
  testWidgets(
    'Registration validates confirmation then verifies email before signing in',
    (tester) async {
      final paths = <String>[];
      AccountSession? accepted;
      final api = AccountAuthApi(
        baseUrl: 'http://test/api',
        client: MockClient((request) async {
          paths.add(request.url.path);
          if (request.url.path.endsWith('/register')) {
            expect(jsonDecode(request.body), {
              'fullName': 'Người mới',
              'email': 'new@example.com',
              'password': 'Password123!',
            });
            return jsonResponse({'challengeId': challenge, 'message': 'sent'});
          }
          expect(jsonDecode(request.body), {
            'challengeId': challenge,
            'code': '123456',
          });
          return jsonResponse(loginResponse);
        }),
      );
      addTearDown(api.close);
      await openScreen(tester, api, (session) => accepted = session);
      await click(tester, 'Đăng ký ngay');
      await tester.enterText(find.byType(TextFormField).at(0), 'Người mới');
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'new@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(2), 'Password123!');
      await tester.enterText(
        find.byType(TextFormField).at(3),
        'does-not-match',
      );
      await click(tester, 'Đăng ký');
      expect(find.text('Mật khẩu xác nhận chưa khớp'), findsOneWidget);
      expect(paths, isEmpty);
      await tester.enterText(find.byType(TextFormField).at(3), 'Password123!');
      await click(tester, 'Đăng ký');
      expect(find.text('Xác nhận email'), findsOneWidget);
      expect(accepted, isNull);
      await tester.enterText(find.byType(TextFormField), '123456');
      await click(tester, 'Xác nhận & đăng nhập');
      expect(paths, ['/api/auth/register', '/api/auth/verify-registration']);
      expect(accepted?.user['roleCode'], 'EMPLOYEE');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('Forgot password resets through code then returns to login', (
    tester,
  ) async {
    final paths = <String>[];
    final api = AccountAuthApi(
      baseUrl: 'http://test/api',
      client: MockClient((request) async {
        paths.add(request.url.path);
        if (request.url.path.endsWith('/forgot-password'))
          return jsonResponse({'challengeId': challenge});
        expect(jsonDecode(request.body), {
          'challengeId': challenge,
          'code': '123456',
          'password': 'NewPassword123!',
        });
        return jsonResponse({'message': 'changed'});
      }),
    );
    addTearDown(api.close);
    await openScreen(tester, api, (_) => fail('Reset must not auto-login'));
    await click(tester, 'Quên mật khẩu?');
    await tester.enterText(find.byType(TextFormField), 'new@example.com');
    await click(tester, 'Gửi mã xác nhận');
    expect(find.text('Đặt lại mật khẩu'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), '123456');
    await tester.enterText(find.byType(TextFormField).at(1), 'NewPassword123!');
    await tester.enterText(find.byType(TextFormField).at(2), 'NewPassword123!');
    await click(tester, 'Lưu mật khẩu mới');
    expect(paths, ['/api/auth/forgot-password', '/api/auth/reset-password']);
    expect(
      find.text('Đã đổi mật khẩu. Đăng nhập bằng mật khẩu mới để tiếp tục.'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).at(0))
          .controller!
          .text,
      'new@example.com',
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Credential login invokes authenticated callback without demo bypass',
    (tester) async {
      AccountSession? accepted;
      final api = AccountAuthApi(
        baseUrl: 'http://test/api',
        client: MockClient((_) async => jsonResponse(loginResponse)),
      );
      addTearDown(api.close);
      await openScreen(tester, api, (session) => accepted = session);
      await tester.enterText(
        find.byType(TextFormField).at(0),
        'new@example.com',
      );
      await tester.enterText(find.byType(TextFormField).at(1), 'Password123!');
      await click(tester, 'Đăng nhập');
      expect(accepted?.token, 'smh_test_token');
      expect(find.text('Dùng tài khoản trải nghiệm'), findsNothing);
    },
  );
}
