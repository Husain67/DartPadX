import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todoistx_local/src/app.dart';
import 'package:todoistx_local/src/common/providers/data_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todoistx_local/src/common/services/database_service.dart';

Future<void> main() async {
  // Ensure that Flutter bindings are initialized
  // (सुनिश्चित करें कि स्पंदन बाइंडिंग प्रारंभ हो गए हैं)
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  final prefs = await SharedPreferences.getInstance();
  await DatabaseService.instance.init();

  // Create a provider container to initialize notification service
  // We override the sharedPreferencesProvider to pass the instance we got.
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ]
  );

  // Initialize notification service
  await container.read(notificationServiceProvider).init();

  // Run the app with Riverpod
  // (रिवरपॉड के साथ ऐप चलाएं)
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );
}