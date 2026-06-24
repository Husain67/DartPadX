import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/file_model.dart';
import 'models/compiler_preset.dart';
import 'core/theme.dart';
import 'screens/main_screen.dart';
import 'providers/file_provider.dart';
import 'providers/compiler_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(FileModelAdapter());
  Hive.registerAdapter(CompilerPresetAdapter());

  final container = ProviderContainer();
  await container.read(fileProvider.notifier).init();
  await container.read(compilerProvider.notifier).init();

  runApp(
    UncontrolledProviderScope(
      container: container,
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
      theme: DartMiniTheme.darkTheme,
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
