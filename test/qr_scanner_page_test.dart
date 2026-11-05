import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supermarket_hrm/features/backend/qr_scanner_page.dart';

void main() {
  testWidgets(
    'QrScannerPage renders camera view, flash, switch camera, guidance and no manual entry',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      String? poppedResult;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  poppedResult = await Navigator.of(context).push<String>(
                    MaterialPageRoute(
                      builder: (_) => const QrScannerPage(
                        title: 'Quét QR Check-in',
                      ),
                    ),
                  );
                },
                child: const Text('Open Scanner'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Scanner'));
      await tester.pumpAndSettle();

      // Title & Navigation
      expect(find.text('Quét QR Check-in'), findsOneWidget);
      expect(find.byTooltip('Quay lại'), findsOneWidget);

      // Flash & Switch camera actions
      expect(find.byTooltip('Bật đèn flash'), findsOneWidget);
      expect(find.byTooltip('Đổi camera'), findsOneWidget);

      // Guidance instruction
      expect(
        find.text('Đưa mã QR của quản lý vào khung để quét.'),
        findsOneWidget,
      );

      // Strictly NO manual text input or manual buttons
      expect(find.byType(TextField), findsNothing);
      expect(find.textContaining('nhập mã thủ công'), findsNothing);
      expect(find.textContaining('Nhập mã thủ công'), findsNothing);

      // Back button pops null
      await tester.tap(find.byTooltip('Quay lại'));
      await tester.pumpAndSettle();
      expect(poppedResult, isNull);
    },
  );
}
