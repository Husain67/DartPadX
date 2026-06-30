import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/file_model.dart';
import 'models/preset_model.dart';
import 'providers/file_provider.dart';
import 'providers/preset_provider.dart';
import 'screens/main_screen.dart';
import 'theme.dart';
import 'utils/shortcuts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(FileModelAdapter());
  Hive.registerAdapter(PresetModelAdapter());

  final fileBox = await Hive.openBox<FileModel>('files');
  final presetBox = await Hive.openBox<PresetModel>('presets');
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        fileBoxProvider.overrideWithValue(fileBox),
        presetBoxProvider.overrideWithValue(presetBox),
        sharedPrefsProvider.overrideWithValue(prefs),
      ],
      child: const DartMiniIdeApp(),
    ),
  );
}

class DartMiniIdeApp extends StatelessWidget {
  const DartMiniIdeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DartMini IDE',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const IdeShortcuts(child: MainScreen()),
    );
  }
}
