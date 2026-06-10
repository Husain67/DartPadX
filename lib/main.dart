import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/dart_file.dart';
import 'models/compiler_preset.dart';
import 'screens/main_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  Hive.registerAdapter(DartFileAdapter());
  Hive.registerAdapter(CompilerPresetAdapter());

  await Hive.openBox<DartFile>('files');
  await Hive.openBox<CompilerPreset>('compiler_presets');

  runApp(const ProviderScope(child: DartMiniIDE()));
}

class DartMiniIDE extends StatelessWidget {
  const DartMiniIDE({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DartMini IDE',
      theme: AppTheme.darkTheme,
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
