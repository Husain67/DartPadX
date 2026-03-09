# Fix unused imports
sed -i "s/import 'dart:convert';//" dart_mini_ide/lib/models/compiler_preset.dart
sed -i "s/import 'dart:convert';//" dart_mini_ide/lib/providers/compiler_provider.dart
sed -i "s/import 'dart:convert';//" dart_mini_ide/lib/widgets/toolbar_widget.dart

# Fix examples_screen.dart interpolation & trailing comma issues
sed -i "s/final filename = ex\['title'\]!.toLowerCase().replaceAll(' ', '_') + '.dart';/final filename = '\${ex['title']!.toLowerCase().replaceAll(' ', '_')}.dart';/" dart_mini_ide/lib/screens/examples_screen.dart
sed -i "s/Fluttertoast.showToast(msg: 'Loaded \${ex\['title'\]}');/Fluttertoast.showToast(msg: 'Loaded \${ex[\"title\"]}');/" dart_mini_ide/lib/screens/examples_screen.dart

# Fix value -> initialValue
sed -i "s/value: _method/initialValue: _method/" dart_mini_ide/lib/screens/settings_screen.dart
sed -i "s/value: _authType/initialValue: _authType/" dart_mini_ide/lib/screens/settings_screen.dart

# Fix withOpacity
sed -i "s/Colors.white.withOpacity(0.1)/Colors.white.withValues(alpha: 0.1)/" dart_mini_ide/lib/screens/settings_screen.dart
sed -i "s/Colors.black.withOpacity(0.5)/Colors.black.withValues(alpha: 0.5)/" dart_mini_ide/lib/widgets/output_sheet.dart

# Fix const missing
sed -i "s/BorderSide(color: AppTheme.primaryAccent, width: 2)/const BorderSide(color: AppTheme.primaryAccent, width: 2)/" dart_mini_ide/lib/screens/settings_screen.dart
sed -i "s/BorderSide(color: Colors.white12, width: 1)/const BorderSide(color: Colors.white12, width: 1)/" dart_mini_ide/lib/screens/settings_screen.dart

# Fix background -> surface
sed -i "s/background: backgroundStart,//" dart_mini_ide/lib/theme/app_theme.dart

# Fix DartFormatter required argument
sed -i "s/DartFormatter()/DartFormatter(languageVersion: DartFormatter.latestLanguageVersion)/" dart_mini_ide/lib/widgets/editor_widget.dart

# Fix BoxConstraints const
sed -i "s/constraints: const BoxConstraints()/constraints: BoxConstraints()/" dart_mini_ide/lib/widgets/output_sheet.dart
