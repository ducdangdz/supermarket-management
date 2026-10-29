import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supermarket_hrm/core/network/team_api.dart';
import 'package:supermarket_hrm/features/attendance/data/attendance_repository.dart';
import 'package:supermarket_hrm/features/attendance/models/attendance_models.dart';

http.Response reply(Object body, [int status = 200]) => http.Response(
  jsonEncode(body),
  status,
  headers: {'content-type': 'application/json'},
);
void main() {
  tearDown(() => TeamApi.active?.close());
  test(
    'Attendance default repository uses real session even without dart define',
    () async {
      TeamApi.active = TeamApi(
        employeeId: 42,
        token: 'smh_real',
        client: MockClient((r) async {
          expect(r.url.path, '/api/attendance/me/today');
          expect(r.headers['Authorization'], 'Bearer smh_real');
          return reply([]);
        }),
      );
      expect(AttendanceRepository.create(), isA<RemoteAttendanceRepository>());
      expect(await AttendanceRepository.create().getTodaySchedules(), isEmpty);
    },
  );
  test('Attendance upload is multipart using the same bearer token', () async {
    TeamApi.active = TeamApi(
      employeeId: 42,
      token: 'smh_real',
      client: MockClient((r) async {
        expect(r.url.path, '/api/attendance/evidence');
        expect(r.headers['Authorization'], 'Bearer smh_real');
        expect(r.headers['content-type'], startsWith('multipart/form-data;'));
        return reply({
          'fileUrl': '/uploads/evidence/x.jpg',
          'fileHash': 'abc',
        }, 201);
      }),
    );
    final result = await AttendanceRepository.create().uploadEvidence(
      EvidencePhoto(
        bytes: Uint8List.fromList([255, 216, 255]),
        fileName: 'selfie.jpg',
        capturedAt: DateTime.now(),
      ),
    );
    expect(result.fileHash, 'abc');
  });
  test(
    'Backend rejection preserves the rule code instead of mock success',
    () async {
      TeamApi.active = TeamApi(
        employeeId: 42,
        token: 'smh_real',
        client: MockClient(
          (r) async =>
              reply({'code': 'EVIDENCE_REQUIRED', 'message': 'Cần ảnh'}, 400),
        ),
      );
      final result = await AttendanceRepository.create().submit(
        AttendanceSubmission(
          action: AttendanceAction.checkIn,
          scheduleId: 7,
          clientTime: DateTime.now(),
          deviceInfo: 'Test',
        ),
      );
      expect(result.success, isFalse);
      expect(result.errorCode, 'EVIDENCE_REQUIRED');
    },
  );
}
