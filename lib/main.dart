import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/services/hive_storage_service.dart';
import 'src/services/preferences_service.dart';
import 'src/theme/app_theme.dart';
import 'src/features/editor/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await PreferencesService.init();
  await HiveStorageService.init();

  runApp(
    const ProviderScope(
      child: DartMiniApp(),
    ),
  );
}

class DartMiniApp extends StatelessWidget {
  const DartMiniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DartMini IDE',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainScreen(),
    );
  }
}
