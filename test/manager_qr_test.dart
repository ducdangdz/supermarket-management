import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:supermarket_hrm/core/network/team_api.dart';
import 'package:supermarket_hrm/models/models.dart';
import 'package:supermarket_hrm/features/management/shifts/shift_qr_dialog.dart';

http.Response reply(Object v, [int status = 200]) => http.Response(
  jsonEncode(v),
  status,
  headers: {'content-type': 'application/json'},
);

void main() {
  testWidgets(
    'Manager creates short-lived QR (60-120s) and can revoke or hide on expiry',
    (tester) async {
      var now = DateTime(2026, 10, 25, 22, 15);
      Map<String, dynamic>? sent;
      Map<String, dynamic>? revoked;

      final api = TeamApi(
        employeeId: 18,
        token: 'smh_manager',
        client: MockClient((r) async {
          expect(r.headers['Authorization'], 'Bearer smh_manager');
          if (r.method == 'GET') {
            return reply([
              {
                'branch_id': 1,
                'work_area_id': 7,
                'area_name': 'Thu ngân',
                'floor_name': 'Tầng 1',
              },
              {
                'branch_id': 2,
                'work_area_id': 99,
                'area_name': 'Khu vực khác',
                'floor_name': 'Tầng 2',
              },
            ]);
          }
          if (r.url.path.endsWith('/revoke')) {
            revoked = jsonDecode(r.body);
            return reply({'message': 'QR đã bị thu hồi.', 'revoked': true});
          }
          sent = jsonDecode(r.body);
          return reply({
            'token': 'real_server_qr',
            'expiresAt': now.add(const Duration(seconds: 90)).toIso8601String(),
          }, 201);
        }),
      );

      final shift = Shift(
        shiftId: 3,
        branchId: 1,
        shiftCode: 'TEST',
        shiftName: 'Ca thử',
        startTime: '22:00',
        endTime: '23:59',
      );

      tester.view.physicalSize = const Size(1024, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ShiftQrDialog(
              shift: shift,
              api: api,
              clock: () => now,
              defaultExpiresInSeconds: 90,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Khu vực khác'), findsNothing);
      expect(find.text('90 giây (1.5 phút)'), findsOneWidget);

      await tester.tap(find.text('Tạo mã QR'));
      await tester.pumpAndSettle();

      expect(sent, {
        'shiftId': 3,
        'workAreaId': 7,
        'sessionType': 'CHECK_IN',
        'expiresInSeconds': 90,
      });
      expect(find.byType(QrImageView), findsOneWidget);
      expect(find.text('Thu hồi mã'), findsOneWidget);

      // Thu hồi mã QR
      await tester.tap(find.text('Thu hồi mã'));
      await tester.pumpAndSettle();
      expect(revoked, {'token': 'real_server_qr'});
      expect(find.byType(QrImageView), findsNothing);

      await tester.pumpWidget(const SizedBox());
      api.close();
    },
  );

  testWidgets('Manager QR hides after expiry', (tester) async {
    var now = DateTime(2026, 10, 25, 22, 15);
    final api = TeamApi(
      employeeId: 18,
      token: 'smh_manager',
      client: MockClient((r) async {
        if (r.method == 'GET') {
          return reply([
            {
              'branch_id': 1,
              'work_area_id': 7,
              'area_name': 'Thu ngân',
              'floor_name': 'Tầng 1',
            },
          ]);
        }
        return reply({
          'token': 'real_server_qr',
          'expiresAt': now.add(const Duration(seconds: 90)).toIso8601String(),
        }, 201);
      }),
    );

    final shift = Shift(
      shiftId: 3,
      branchId: 1,
      shiftCode: 'TEST',
      shiftName: 'Ca thử',
      startTime: '22:00',
      endTime: '23:59',
    );

    tester.view.physicalSize = const Size(1024, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ShiftQrDialog(
            shift: shift,
            api: api,
            clock: () => now,
            defaultExpiresInSeconds: 90,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tạo mã QR'));
    await tester.pumpAndSettle();
    expect(find.byType(QrImageView), findsOneWidget);

    now = now.add(const Duration(seconds: 95));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(QrImageView), findsNothing);
    expect(find.text('Mã đã hết hạn. Hãy tạo mã mới.'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    api.close();
  });

  testWidgets('Backend error does not display a fake QR', (tester) async {
    final api = TeamApi(
      employeeId: 18,
      token: 'smh_manager',
      client: MockClient(
        (r) async => r.method == 'GET'
            ? reply([
                {
                  'branch_id': 1,
                  'work_area_id': 7,
                  'area_name': 'Thu ngân',
                  'floor_name': 'Tầng 1',
                },
              ])
            : reply({'message': 'Không có quyền tạo QR'}, 403),
      ),
    );
    final shift = Shift(
      shiftId: 3,
      branchId: 1,
      shiftCode: 'TEST',
      shiftName: 'Ca thử',
      startTime: '22:00',
      endTime: '23:59',
    );
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: ShiftQrDialog(shift: shift, api: api))),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tạo mã QR'));
    await tester.pumpAndSettle();
    expect(find.byType(QrImageView), findsNothing);
    expect(find.text('Không có quyền tạo QR'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    api.close();
  });
}
