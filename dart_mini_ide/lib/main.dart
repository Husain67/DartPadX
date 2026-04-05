import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'models/code_file.dart';
import 'models/compiler_preset.dart';
import 'ui/main_screen.dart';
import 'ui/widgets/examples_gallery.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(CodeFileAdapter());
  Hive.registerAdapter(CompilerPresetAdapter());

  await Hive.openBox<CodeFile>('filesBox');
  await Hive.openBox<CompilerPreset>('presetsBox');

  runApp(
    const ProviderScope(
      child: DartMiniIDEApp(),
    ),
  );
}

class DartMiniIDEApp extends StatelessWidget {
  const DartMiniIDEApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DartMini IDE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF050505),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFACC15),
          surface: Color(0xFF1a1a1a),
        ),
        useMaterial3: true,
      ),
      routes: {
        '/': (context) => const MainScreen(),
        '/examples': (context) => const ExamplesGallery(),
      },
    );
  }
}
