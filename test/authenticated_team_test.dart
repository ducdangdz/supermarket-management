import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:supermarket_hrm/core/network/team_api.dart';
import 'package:supermarket_hrm/core/theme/app_theme.dart';
import 'package:supermarket_hrm/features/backend/backend_workspace.dart';
import 'package:supermarket_hrm/features/launcher/authenticated_team_home.dart';
import 'package:supermarket_hrm/features/management/manager_main_screen.dart';
import 'package:supermarket_hrm/services/mock_data_service.dart';

http.Response response(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json; charset=utf-8'},
);
Map<String, Object> snapshot() => {
  'roles': [
    {'role_id': 17, 'role_code': 'EMPLOYEE', 'role_name': 'Nhân viên'},
    {'role_id': 23, 'role_code': 'MANAGER', 'role_name': 'Quản lý'},
  ],
  'branches': [],
  'employees': [
    {
      'employee_id': 42,
      'role_id': 17,
      'branch_id': null,
      'employee_code': 'DB42',
      'full_name': 'Nhân viên từ SQL',
      'email': 'db@example.com',
      'employment_status': 'ACTIVE',
    },
  ],
  'floors': [],
  'areas': [],
  'shifts': [],
  'schedules': [],
  'attendance': [],
  'evidence': [],
};
void main() {
  setUpAll(() => initializeDateFormatting('vi'));
  for (final role in ['EMPLOYEE', 'MANAGER', 'ADMIN', 'HR']) {
    testWidgets(
      'Real $role opens team home with fixed role and original modules',
      (tester) async {
        tester.view.physicalSize = const Size(1440, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final api = TeamApi(
          employeeId: 42,
          token: 'smh_test',
          client: MockClient((request) async {
            expect(request.headers['Authorization'], 'Bearer smh_test');
            if (request.url.path.endsWith('/team-data'))
              return response(snapshot());
            if (request.url.path.endsWith('/schedules')) return response([]);
            return response({
              'employeeId': 42,
              'employeeCode': 'DB42',
              'fullName': 'Tên thật từ SQL',
              'email': 'db@example.com',
              'roleName': role,
            });
          }),
        );
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.lightTheme,
            home: AuthenticatedTeamHome(
              api: api,
              session: Session(
                employeeId: 42,
                idToken: 'smh_test',
                fullName: 'Tên thật từ SQL',
                email: 'db@example.com',
                roleCode: role,
                roleName: role,
              ),
              onLogout: () async {},
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Xin chào, Tên thật từ SQL'), findsOneWidget);
        expect(find.text('Kết nối hệ thống'), findsNothing);
        expect(
          tester
              .widgetList<ChoiceChip>(find.byType(ChoiceChip))
              .every((chip) => chip.onSelected == null),
          isTrue,
        );
        if (role == 'EMPLOYEE') {
          expect(find.text('Quản lý vận hành'), findsNothing);
          await tester.tap(find.text('Vào không gian nhân viên'));
          await tester.pumpAndSettle();
          expect(find.text('Dashboard nhân viên'), findsOneWidget);
          expect(find.text('Tên thật từ SQL'), findsOneWidget);
        } else {
          await tester.tap(find.text('Vào không gian quản lý'));
          await tester.pumpAndSettle();
          expect(find.byType(ManagerMainScreen), findsOneWidget);
          // The pushed route must keep the authenticated provider, not the outer demo data.
          final context = tester.element(find.byType(ManagerMainScreen));
          expect(context.read<MockDataService>().isRemote, isTrue);
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
  test('Failed backend read never substitutes sample employees', () async {
    final api = TeamApi(
      employeeId: 42,
      token: 'smh_t',
      client: MockClient(
        (_) async => response({'message': 'Database unavailable'}, 500),
      ),
    );
    final data = MockDataService(remoteApi: api, roleCode: 'MANAGER');
    await expectLater(data.refresh(), throwsA(isA<Exception>()));
    expect(data.employees, isEmpty);
    expect(data.attendanceRecords, isEmpty);
    data.setCurrentRole('ADMIN');
    expect(data.currentRoleCode, 'MANAGER');
    api.close();
    data.dispose();
  });
  test('Rejected server write does not add a local employee', () async {
    final api = TeamApi(
      employeeId: 42,
      token: 'smh_t',
      client: MockClient((r) async {
        if (r.method == 'GET')
          return response({
            ...snapshot(),
            'branches': [
              {
                'branch_id': 1,
                'branch_code': 'DB',
                'branch_name': 'SQL',
                'address': '',
                'is_active': true,
              },
            ],
          });
        return response({'message': 'Duplicate employee'}, 409);
      }),
    );
    final data = MockDataService(remoteApi: api, roleCode: 'ADMIN');
    await data.refresh();
    final existing = data.employees.length;
    await expectLater(
      data.addEmployee(data.employees.first),
      throwsA(isA<Exception>()),
    );
    expect(data.employees.length, existing);
    api.close();
    data.dispose();
  });
}
