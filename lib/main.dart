import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'theme/app_theme.dart';
import 'screens/main_screen.dart';
import 'models/code_file.dart';
import 'models/compiler_preset.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  // Register manual adapters
  Hive.registerAdapter(CodeFileAdapter());
  Hive.registerAdapter(CompilerPresetAdapter());

  // Open Boxes
  await Hive.openBox<CodeFile>(AppConstants.hiveBoxFiles);
  await Hive.openBox<CompilerPreset>(AppConstants.hiveBoxPresets);
  await Hive.openBox(AppConstants.hiveBoxSettings);

  runApp(const ProviderScope(child: DartMiniIDEApp()));
}

class DartMiniIDEApp extends StatelessWidget {
  const DartMiniIDEApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainScreen(),
    );
  }
}
