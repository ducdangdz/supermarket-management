import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_colors.dart';
import 'features/launcher/feature_launcher_screen.dart';
// Mở import bên dưới khi bạn muốn chạy thẳng 1 màn hình độc lập:
// import 'features/reports/screens/attendance_overview_report_screen.dart';
// import 'features/reports/screens/employee_attendance_report_screen.dart';
// import 'features/reports/screens/late_absent_report_screen.dart';
// import 'features/reports/screens/detailed_attendance_history_screen.dart';
// import 'features/reports/screens/export_report_screen.dart';
// import 'features/management/manager_main_screen.dart';
import 'services/mock_data_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MockDataService()),
      ],
      child: const SmartMarketHrmApp(),
    ),
  );
}

class SmartMarketHrmApp extends StatelessWidget {
  const SmartMarketHrmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SmartMarket HRM',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          surface: AppColors.surface,
        ),
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
        ),
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('vi', 'VN'),
        Locale('en', 'US'),
      ],
      // =========================================================================
      // CÁCH CHẠY RIÊNG TỪNG CHỨC NĂNG:
      // Mặc định đang mở: FeatureLauncherScreen() để bạn bấm chọn màn nào tùy thích.
      // Nếu bạn muốn ứng dụng khởi động VÀO THẲNG 1 MÀN DUY NHẤT, chỉ cần mở comment bên dưới:
      //
      // home: const AttendanceOverviewReportScreen(), // <-- Chạy riêng Màn 1: Tổng quan báo cáo
      // home: const EmployeeAttendanceReportScreen(),   // <-- Chạy riêng Màn 2: Báo cáo theo nhân viên
      // home: const LateAbsentReportScreen(),           // <-- Chạy riêng Màn 3: Báo cáo đi muộn/vắng
      // home: const DetailedAttendanceHistoryScreen(),  // <-- Chạy riêng Màn 4: Lịch sử chi tiết (GPS, QR)
      // home: const ExportReportScreen(),                // <-- Chạy riêng Màn 5: Xuất báo cáo Excel/PDF
      // home: const ManagerMainScreen(),                // <-- Chạy giao diện gộp chung ban đầu
      // =========================================================================
      home: const FeatureLauncherScreen(),
    );
  }
}
