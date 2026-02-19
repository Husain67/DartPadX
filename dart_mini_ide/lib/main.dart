import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/file_model.dart';
import 'models/compiler_preset.dart';
import 'utils/constants.dart';
import 'ui/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  Hive.registerAdapter(FileModelAdapter());
  Hive.registerAdapter(CompilerPresetAdapter());

  // Pre-open boxes to ensure data is ready
  await Hive.openBox<FileModel>('files');
  await Hive.openBox<CompilerPreset>('compiler_presets');
  await Hive.openBox('settings');

  runApp(const ProviderScope(child: DartMiniIdeApp()));
}

class DartMiniIdeApp extends StatelessWidget {
  const DartMiniIdeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DartMini IDE',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      home: const HomeScreen(),
    );
  }
}
