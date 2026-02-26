import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'data/hive_adapters.dart';
import 'models/code_file.dart';
import 'models/compiler_preset.dart';
import 'ui/screens/home_screen.dart';
import 'ui/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  HiveAdapters.register();

  await Hive.openBox<CodeFile>('code_files');
  await Hive.openBox<CompilerPreset>('compiler_presets');

  runApp(const ProviderScope(child: DartMiniApp()));
}

class DartMiniApp extends StatelessWidget {
  const DartMiniApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DartMini IDE',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const HomeScreen(),
    );
  }
}
