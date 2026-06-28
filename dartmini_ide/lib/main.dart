import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/app_file.dart';
import 'models/compiler_preset.dart';
import 'providers/compiler_provider.dart';
import 'ui/theme.dart';
import 'ui/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(AppFileAdapter());
  Hive.registerAdapter(CompilerPresetAdapter());

  await Hive.openBox<AppFile>('files');
  await Hive.openBox<CompilerPreset>('presets');

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
      ],
      child: const DartMiniApp(),
    ),
  );
}

class DartMiniApp extends StatelessWidget {
  const DartMiniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DartMini IDE',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: const ScaffoldGradientWrapper(child: HomeScreen()),
    );
  }
}

class ScaffoldGradientWrapper extends StatelessWidget {
  final Widget child;
  const ScaffoldGradientWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.backgroundGradient,
      child: child,
    );
  }
}
