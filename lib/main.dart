import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/file_model.dart';
import 'models/compiler_preset.dart';
import 'ui/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  Hive.registerAdapter(FileModelAdapter());
  Hive.registerAdapter(CompilerPresetAdapter());

  await Hive.openBox<FileModel>('files');
  await Hive.openBox<CompilerPreset>('presets');
  await Hive.openBox<String>('settings');

  // Insert default 'untitled.dart' if files box is empty
  final filesBox = Hive.box<FileModel>('files');
  if (filesBox.isEmpty) {
    const defaultCode = '''void main() {
  print('Hello, DartMini!');
}''';
    await filesBox.put('main.dart', FileModel(
      id: 'main.dart',
      name: 'main.dart',
      content: defaultCode,
      lastModified: DateTime.now(),
    ));
  }

  runApp(
    const ProviderScope(
      child: DartMiniApp(),
    ),
  );
}

class DartMiniApp extends StatelessWidget {
  const DartMiniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DartMini',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF050505),
        primaryColor: const Color(0xFFFACC15),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFACC15),
          secondary: Color(0xFFFACC15),
          surface: Color(0xFF1a1a1a),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          elevation: 0,
        ),
      ),
      home: const MainScreen(),
    );
  }
}
