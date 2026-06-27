import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/file_model.dart';
import 'models/preset_model.dart';
import 'theme/app_theme.dart';
import 'screens/editor_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(FileModelAdapter());
  Hive.registerAdapter(PresetModelAdapter());

  await Hive.openBox<FileModel>('files');
  await Hive.openBox<PresetModel>('presets');
  await Hive.openBox('settings');

  runApp(const ProviderScope(child: DartMiniIDE()));
}

class DartMiniIDE extends StatelessWidget {
  const DartMiniIDE({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DartMini IDE',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const EditorScreen(),
    );
  }
}
