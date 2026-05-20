import 'theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'models/models.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(FileModelAdapter());
  Hive.registerAdapter(PresetModelAdapter());

  await Hive.openBox<FileModel>('files');
  await Hive.openBox<PresetModel>('presets');

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DartMini IDE',
      theme: AppTheme.darkTheme,
      home: const MainScreen(),
    );
  }
}
