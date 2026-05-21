import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/file_model.dart';
import 'models/compiler_preset_model.dart';
import 'providers/file_provider.dart';
import 'providers/preset_provider.dart';
import 'screens/main_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(FileModelAdapter());
  Hive.registerAdapter(CompilerPresetModelAdapter());

  // Open Boxes
  await Hive.openBox('prefsBox');
  await Hive.openBox<FileModel>('filesBox');
  await Hive.openBox<CompilerPresetModel>('presetsBox');

  runApp(
    const ProviderScope(
      child: DartMiniIDEApp(),
    ),
  );
}

class DartMiniIDEApp extends ConsumerStatefulWidget {
  const DartMiniIDEApp({super.key});

  @override
  ConsumerState<DartMiniIDEApp> createState() => _DartMiniIDEAppState();
}

class _DartMiniIDEAppState extends ConsumerState<DartMiniIDEApp> {
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    _initProviders();
  }

  Future<void> _initProviders() async {
    await ref.read(fileProvider.notifier).init();
    await ref.read(presetProvider.notifier).init();
    setState(() {
      _isInit = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInit) {
      return const MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: Center(child: CircularProgressIndicator(color: Colors.yellow)),
        ),
      );
    }

    return MaterialApp(
      title: 'DartMini IDE',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MainScreen(),
    );
  }
}
