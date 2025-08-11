import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:todoistx_local/src/common/providers/data_providers.dart';
import 'package:todoistx_local/l10n/app_localizations.dart';
import 'package:todoistx_local/src/common/theme/app_theme.dart';
import 'package:todoistx_local/src/routes/app_router.dart';

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeControllerProvider);

    return MaterialApp.router(
      title: 'TodoistX Local',

      // Theme settings
      // (थीम सेटिंग्स)
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,

      // Localization settings
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,

      // Router configuration
      // (राउटर कॉन्फ़िगरेशन)
      routerConfig: goRouter,

      // Hide the debug banner
      // (डीबग बैनर छिपाएं)
      debugShowCheckedModeBanner: false,
    );
  }
}
