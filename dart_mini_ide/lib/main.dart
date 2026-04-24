import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/models.dart';
import 'models/adapters.dart';
import 'providers/file_provider.dart';
import 'providers/preset_provider.dart';
import 'ui/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(CodeFileAdapter());
  Hive.registerAdapter(CompilerPresetAdapter());

  final fileBox = await Hive.openBox<CodeFile>('code_files');
  final presetBox = await Hive.openBox<CompilerPreset>('compiler_presets');

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        fileBoxProvider.overrideWithValue(fileBox),
        presetBoxProvider.overrideWithValue(presetBox),
      ],
      child: MyApp(prefs: prefs),
    ),
  );
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;

  const MyApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DartMini IDE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF050505),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFACC15),
          surface: Color(0xFF1A1A1A),
          surfaceContainer: Color(0xFF050505),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(16)),
          ),
        ),
      ),
      home: const MainScreen(),
    );
  }
}
