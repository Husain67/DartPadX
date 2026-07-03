import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dart_mini_ide/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('files');
  await Hive.openBox('settings');
  await Hive.openBox('presets');

  runApp(
    const ProviderScope(
      child: DartMiniApp(),
    ),
  );
}
