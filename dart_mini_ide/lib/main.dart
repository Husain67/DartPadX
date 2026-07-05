import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/theme.dart';
import 'core/constants.dart';
import 'models/file_model.dart';
import 'models/compiler_preset.dart';
import 'ui/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive and adapters
  await Hive.initFlutter();
  Hive.registerAdapter(FileModelAdapter());
  Hive.registerAdapter(CompilerPresetAdapter());

  await Hive.openBox<FileModel>(AppConstants.hiveFileBox);
  await Hive.openBox<CompilerPreset>(AppConstants.hivePresetBox);

  runApp(
    const ProviderScope(
      child: DartMiniIDE(),
    ),
  );
}

class DartMiniIDE extends StatelessWidget {
  const DartMiniIDE({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: AppTheme.pureBlack,
          body: Container(
            decoration: AppTheme.gradientBackground,
            child: child!,
          ),
        );
      },
      home: const HomeScreen(),
    );
  }
}
