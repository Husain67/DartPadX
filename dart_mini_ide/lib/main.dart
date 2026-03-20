import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/code_file.dart';
import 'models/compiler_preset.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  Hive.registerAdapter(CodeFileAdapter());
  Hive.registerAdapter(CompilerPresetAdapter());

  await Hive.openBox<CodeFile>('files');
  await Hive.openBox<CompilerPreset>('presets');
  await Hive.openBox('prefs');

  runApp(const ProviderScope(child: DartMiniIDEApp()));
}

class DartMiniIDEApp extends StatelessWidget {
  const DartMiniIDEApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DartMini IDE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.transparent,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
          centerTitle: false,
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFACC15),
          surface: Color(0xFF1A1A1A),
          onSurface: Colors.white,
        ),
      ),
      home: const MainScreen(),
    );
  }
}
