import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/project_file.dart';
import 'models/compiler_preset.dart';
import 'screens/main_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  Hive.registerAdapter(ProjectFileAdapter());
  Hive.registerAdapter(CompilerPresetAdapter());

  await Hive.openBox<ProjectFile>('files');
  await Hive.openBox<CompilerPreset>('presets');
  await Hive.openBox('settings');

  runApp(const ProviderScope(child: DartMiniApp()));
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
