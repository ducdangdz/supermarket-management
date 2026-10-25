import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:supermarket_hrm/core/theme/app_theme.dart';
import 'package:supermarket_hrm/features/launcher/professional_home.dart';
import 'package:supermarket_hrm/features/management/employees/employee_editor_dialog.dart';
import 'package:supermarket_hrm/models/employee.dart' as account;
import 'package:supermarket_hrm/models/models.dart';
import 'package:supermarket_hrm/services/mock_data_service.dart';

Widget home(MockDataService data, {String role = 'ADMIN'}) =>
    ChangeNotifierProvider.value(
      value: data,
      child: MaterialApp(debugShowCheckedModeBanner:false,
        theme: AppTheme.lightTheme,
        home: ProfessionalHome(
          employee: const account.Employee(
            id: '42',
            name: 'Nguyễn Minh Anh',
            email: 'minhanh@example.com',
            phone: '',
            role: 'Quản trị viên',
            branch: 'SmartMarket · Chi nhánh trung tâm',
            employeeCode: 'NV42',
          ),
          roleCode: role,
          data: data,
          onEmployee: () {},
          onManager: (_) {},
          onReports: () {},
          onLogout: () async {},
          onRefresh: () async {},
          updatedAt: DateTime(2026, 10, 22, 9, 30),
        ),
      ),
    );

class SavingData extends MockDataService {
  int writes = 0;
  final finish = Completer<void>();
  @override
  Future<void> addEmployee(Employee employee) async {
    writes++;
    await finish.future;
  }
}

void main() {
  setUpAll(() => initializeDateFormatting('vi'));
  for (final width in [320.0, 390.0, 1440.0]) {
    testWidgets('Professional home fits width $width', (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final data = MockDataService();
      await tester.pumpWidget(home(data));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Vào không gian quản lý'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('Search filters navigation and shows an empty state', (
    tester,
  ) async {
    await tester.pumpWidget(home(MockDataService()));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'không có chức năng');
    await tester.pumpAndSettle();
    expect(
      find.text('Không tìm thấy chức năng phù hợp. Thử từ khóa khác.'),
      findsOneWidget,
    );
    expect(find.text('Vào không gian quản lý'), findsNothing);
  });
  testWidgets('Employee cannot see management cards', (tester) async {
    await tester.pumpWidget(home(MockDataService(), role: 'EMPLOYEE'));
    await tester.pumpAndSettle();
    expect(find.text('Quản lý vận hành'), findsNothing);
    expect(find.text('Báo cáo & thống kê'), findsNothing);
  });
  testWidgets(
    'Employee form validates fields and blocks duplicate submission',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final data = SavingData();
      await tester.pumpWidget(
        MaterialApp(debugShowCheckedModeBanner:false,
          theme: AppTheme.lightTheme,
          home: Builder(
            builder: (ctx) => Scaffold(
              body: TextButton(
                onPressed: () => showDialog<void>(
                  context: ctx,
                  builder: (_) => EmployeeEditorDialog(data: data),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Lưu nhân viên'));
      await tester.pumpAndSettle();
      expect(data.writes, 0);
      expect(find.text('Vui lòng nhập thông tin này.'), findsWidgets);
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Nhân viên kiểm thử');
      await tester.enterText(fields.at(1), 'NV-NEW');
      await tester.enterText(fields.at(2), 'wrong-email');
      await tester.tap(find.text('Lưu nhân viên'));
      await tester.pumpAndSettle();
      expect(find.text('Địa chỉ email chưa hợp lệ.'), findsOneWidget);
      expect(data.writes, 0);
      await tester.enterText(fields.at(2), 'new@example.com');
      await tester.tap(find.text('Lưu nhân viên'));
      await tester.pump();
      expect(data.writes, 1);
      expect(find.text('Đang lưu...'), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      data.finish.complete();
      await tester.pumpAndSettle();
      expect(find.byType(EmployeeEditorDialog), findsNothing);
    },
  );
}
