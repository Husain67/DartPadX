import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/hive_service.dart';
import 'ui/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveService.init();
  runApp(const ProviderScope(child: DartMiniIdeApp()));
}

class DartMiniIdeApp extends StatelessWidget {
  const DartMiniIdeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DartMini IDE',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF050505),
        primaryColor: const Color(0xFFFACC15),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFACC15),
          surface: Color(0xFF1a1a1a),
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
