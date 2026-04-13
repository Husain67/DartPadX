1. *Setup Dependencies and pubspec.yaml*
   - Update `pubspec.yaml` with the required dependencies (flutter_code_editor, hive, flutter_riverpod, dart_style, etc.) and target `sdk: ^3.5.0`.
   - Remove standard platform directories (`android/`, `ios/`, etc.) from the workspace, keeping `lib/` and `test/`.
   - Delete `analysis_options.yaml`.
   - Run `flutter pub get` and verify changes with `ls`.

2. *Create CodeFile Model*
   - Create `lib/models/code_file.dart`.
   - Implement `CodeFile` (HiveType 0) with id, name, content, and its manual TypeAdapter.
   - Verify syntax with `flutter analyze`.

3. *Create CompilerPreset Model*
   - Create `lib/models/compiler_preset.dart`.
   - Implement `CompilerPreset` (HiveType 1) with endpoint, method, headers, queryParams, bodyTemplate, response mappings, and its manual TypeAdapter.
   - Verify syntax with `flutter analyze`.

4. *Implement File Provider*
   - Create `lib/providers/file_provider.dart` to manage `CodeFile`s, active file, and Hive persistence (auto-save with 2s debounce).
   - Verify syntax with `flutter analyze`.

5. *Implement Preset Provider*
   - Create `lib/providers/preset_provider.dart` to manage predefined and custom compiler presets.
   - Verify syntax with `flutter analyze`.

6. *Implement Settings Provider*
   - Create `lib/providers/settings_provider.dart` to toggle default OneCompiler vs custom preset.
   - Verify syntax with `flutter analyze`.

7. *Implement Execution Provider*
   - Create `lib/providers/execution_provider.dart` for API execution logic, state (loading, stdout, stderr, time, memory).
   - Verify syntax with `flutter analyze`.

8. *Build Main Editor UI*
   - Create `lib/ui/main_editor.dart`.
   - Build the deep dark Material 3 UI with AppBar, Horizontal Scrollable Toolbar, File Tabs, and `flutter_code_editor` integration.
   - Verify syntax with `flutter analyze`.

9. *Build Output Sheet*
   - Create `lib/ui/output_sheet.dart` to implement Draggable Bottom Sheet (`initialChildSize: 0.20`) for console output.
   - Verify syntax with `flutter analyze`.

10. *Implement Editor Actions*
    - Create `lib/utils/editor_actions.dart` to implement Toolbar actions (New, Import, Copy, Paste, Download, Share, Delete, Format).
    - Verify syntax with `flutter analyze`.

11. *Build Settings Screen*
    - Create `lib/ui/settings/settings_screen.dart` to view compiler presets and provide access to edit/delete/duplicate presets.
    - Verify syntax with `flutter analyze`.

12. *Build Preset Editor*
    - Create `lib/ui/settings/preset_editor.dart` with forms for endpoint URL, HTTP method, auth type, headers/query params, request body template, response mapping.
    - Verify syntax with `flutter analyze`.

13. *Setup Main and Testing*
    - Update `lib/main.dart` to initialize Hive, Riverpod, and load the main app.
    - Delete `test/widget_test.dart` and create `test/app_test.dart` with a basic test.
    - Run `flutter test`.

14. *Complete pre commit steps*
    - Complete pre-commit steps to ensure proper testing, verification, review, and reflection are done.

15. *Submit the change*
