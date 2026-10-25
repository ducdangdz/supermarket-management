import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'features/backend/backend_workspace.dart';
import 'services/mock_data_service.dart';
import 'core/services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService.init();
  await initializeDateFormatting('vi');
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => MockDataService())],
      child: const SmartMarketHrmApp(),
    ),
  );
}

class SmartMarketHrmApp extends StatelessWidget {
  const SmartMarketHrmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const SmartMarketApp();
  }
}
