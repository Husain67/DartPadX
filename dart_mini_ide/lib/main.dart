import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/project_file.dart';
import 'models/compiler_preset.dart';
import 'theme/app_theme.dart';
import 'ui/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  Hive.registerAdapter(ProjectFileAdapter());
  Hive.registerAdapter(CompilerPresetAdapter());

  await Hive.openBox<ProjectFile>('projectFiles');
  await Hive.openBox<CompilerPreset>('compilerPresets');

  runApp(const ProviderScope(child: DartMiniIDEApp()));
}

class DartMiniIDEApp extends StatelessWidget {
  const DartMiniIDEApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DartMini IDE',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: HomeScreen(),
    );
  }
}
