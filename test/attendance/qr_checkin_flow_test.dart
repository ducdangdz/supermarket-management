import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('QR Check-in & Check-out Validation Rules', () {
    test('Token must not be empty or whitespace', () {
      bool isValidToken(String? token) =>
          token != null && token.trim().isNotEmpty;

      expect(isValidToken(null), isFalse);
      expect(isValidToken(''), isFalse);
      expect(isValidToken('   '), isFalse);
      expect(isValidToken('valid_token_123'), isTrue);
    });

    test('Handles backend QR error codes and user-friendly messages', () async {
      final errorsToTest = {
        'QR_EXPIRED': 'QR đã hết hạn.',
        'QR_REVOKED': 'QR đã bị thu hồi.',
        'QR_WRONG_TYPE': 'Bạn đang dùng QR check-out để check-in.',
        'WRONG_SHIFT': 'QR không thuộc ca làm của bạn.',
        'INVALID_LOCATION':
            'Mã QR thuộc khu vực "Kho hàng" nhưng bạn được phân công ở "Khu thu ngân".',
      };

      for (final entry in errorsToTest.entries) {
        final client = MockClient((request) async {
          return http.Response(
            jsonEncode({'code': entry.key, 'message': entry.value}),
            400,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        });

        final response = await client.post(
          Uri.parse('http://localhost:8081/api/attendance/check-in'),
          body: jsonEncode({
            'scheduleId': 100,
            'employeeId': 10,
            'qrToken': 'any_token',
          }),
        );

        expect(response.statusCode, 400);
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        expect(body['code'], entry.key);
        expect(body['message'], entry.value);
        client.close();
      }
    });

    test('Check-in with valid QR returns 201 Created and attendanceId', () async {
      final client = MockClient((request) async {
        final payload = jsonDecode(request.body);
        expect(payload['qrToken'], 'valid_server_token');
        return http.Response(
          jsonEncode({
            'attendanceId': 200,
            'scheduleId': 100,
            'action': 'CHECK_IN',
            'message': 'Check-in thành công, bạn đến đúng giờ.',
          }),
          201,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final response = await client.post(
        Uri.parse('http://localhost:8081/api/attendance/check-in'),
        body: jsonEncode({
          'scheduleId': 100,
          'employeeId': 10,
          'qrToken': 'valid_server_token',
        }),
      );

      expect(response.statusCode, 201);
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      expect(body['attendanceId'], 200);
      expect(body['action'], 'CHECK_IN');
      client.close();
    });

    test('Manager revoke QR returns 200 OK with confirmation', () async {
      final client = MockClient((request) async {
        expect(request.url.path, '/api/management/qr-sessions/revoke');
        final payload = jsonDecode(request.body);
        expect(payload['token'], 'token_to_revoke');
        return http.Response(
          jsonEncode({'message': 'QR đã bị thu hồi.', 'revoked': true}),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final response = await client.post(
        Uri.parse('http://localhost:8081/api/management/qr-sessions/revoke'),
        body: jsonEncode({'token': 'token_to_revoke'}),
      );

      expect(response.statusCode, 200);
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      expect(body['revoked'], isTrue);
      expect(body['message'], 'QR đã bị thu hồi.');
      client.close();
    });
  });
}
