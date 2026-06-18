import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../core/theme.dart';
import '../../providers/compiler_provider.dart';
import '../../providers/file_provider.dart';
import '../../models/compiler_preset.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'compiler_preset_editor.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Examples'),
              Tab(text: 'Compiler Presets'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ExamplesTab(),
            CompilerPresetsTab(),
          ],
        ),
      ),
    );
  }
}

class ExamplesTab extends ConsumerWidget {
  const ExamplesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final examples = [
      {'title': 'Hello World', 'code': 'void main() {\n  print("Hello, World!");\n}'},
      {'title': 'Input/Output', 'code': 'import "dart:io";\n\nvoid main() {\n  print("Enter name:");\n  String? name = stdin.readLineSync();\n  print("Hello, $name");\n}'},
      {'title': 'List', 'code': 'void main() {\n  List<int> numbers = [1, 2, 3, 4, 5];\n  for(var num in numbers) {\n    print(num);\n  }\n}'},
      {'title': 'Class', 'code': 'class Person {\n  String name;\n  Person(this.name);\n  void greet() => print("Hi, I am $name");\n}\n\nvoid main() {\n  var p = Person("Dart");\n  p.greet();\n}'},
      {'title': 'Async', 'code': 'Future<void> main() async {\n  print("Waiting...");\n  await Future.delayed(Duration(seconds: 1));\n  print("Done!");\n}'},
    ];

    return ListView.builder(
      itemCount: examples.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(examples[index]['title']!, style: const TextStyle(color: AppTheme.textPrimary)),
          subtitle: Text(examples[index]['code']!.replaceAll('\n', ' '), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppTheme.textSecondary, fontFamily: 'monospace')),
          trailing: const Icon(Icons.arrow_forward_ios, color: AppTheme.primaryAccent, size: 16),
          onTap: () {
            ref.read(fileProvider.notifier).createFile('${examples[index]['title']!.replaceAll(' ', '_')}.dart', content: examples[index]['code']!);
            Navigator.pop(context);
            Fluttertoast.showToast(msg: "Loaded ${examples[index]['title']}", backgroundColor: AppTheme.surfaceColor);
          },
        );
      },
    );
  }
}

class CompilerPresetsTab extends ConsumerWidget {
  const CompilerPresetsTab({super.key});

  void _exportPresets(WidgetRef ref) async {
    final state = ref.read(compilerProvider);
    final presetsJson = state.presets.map((p) => {
      'id': p.id,
      'platformName': p.platformName,
      'endpointUrl': p.endpointUrl,
      'httpMethod': p.httpMethod,
      'authType': p.authType,
      'headers': p.headers,
      'queryParams': p.queryParams,
      'requestBodyTemplate': p.requestBodyTemplate,
      'stdoutPath': p.stdoutPath,
      'stderrPath': p.stderrPath,
      'errorPath': p.errorPath,
      'executionTimePath': p.executionTimePath,
      'memoryPath': p.memoryPath,
      'isDefault': p.isDefault,
    }).toList();

    final jsonStr = jsonEncode(presetsJson);
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/dartmini_presets.json');
    await file.writeAsString(jsonStr);
    Fluttertoast.showToast(msg: 'Exported to ${file.path}');
  }

  void _importPresets(WidgetRef ref) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['json']);
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final str = await file.readAsString();
      try {
        final List<dynamic> data = jsonDecode(str);
        for (var item in data) {
           final p = CompilerPreset(
             id: const Uuid().v4(),
             platformName: item['platformName'],
             endpointUrl: item['endpointUrl'],
             httpMethod: item['httpMethod'],
             authType: item['authType'],
             headers: Map<String, String>.from(item['headers'] ?? {}),
             queryParams: Map<String, String>.from(item['queryParams'] ?? {}),
             requestBodyTemplate: item['requestBodyTemplate'],
             stdoutPath: item['stdoutPath'],
             stderrPath: item['stderrPath'],
             errorPath: item['errorPath'],
             executionTimePath: item['executionTimePath'],
             memoryPath: item['memoryPath'],
             isDefault: false,
           );
           ref.read(compilerProvider.notifier).savePreset(p);
        }
        Fluttertoast.showToast(msg: 'Imported successfully');
      } catch (e) {
        Fluttertoast.showToast(msg: 'Failed to import presets', backgroundColor: AppTheme.errorColor);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(compilerProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add New'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CompilerPresetEditor(preset: null)),
                  );
                },
              ),
              IconButton(icon: const Icon(Icons.upload_file), tooltip: 'Import JSON', onPressed: () => _importPresets(ref)),
              IconButton(icon: const Icon(Icons.download), tooltip: 'Export JSON', onPressed: () => _exportPresets(ref)),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: state.presets.length,
            itemBuilder: (context, index) {
              final preset = state.presets[index];
              return ListTile(
                leading: Radio<String>(
                  value: preset.id,
                  groupValue: state.activePresetId,
                  // ignore: deprecated_member_use
                  activeColor: AppTheme.primaryAccent,
                  onChanged: (val) {
                    if (val != null) ref.read(compilerProvider.notifier).setActivePreset(val);
                  },
                ),
                title: Text(preset.platformName, style: const TextStyle(color: AppTheme.textPrimary)),
                subtitle: Text(preset.endpointUrl, style: const TextStyle(color: AppTheme.textSecondary)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy, color: AppTheme.textSecondary),
                      onPressed: () {
                        final copy = preset.copyWith(
                          id: const Uuid().v4(),
                          platformName: '${preset.platformName} Copy',
                          isDefault: false,
                        );
                        ref.read(compilerProvider.notifier).savePreset(copy);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit, color: AppTheme.primaryAccent),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => CompilerPresetEditor(preset: preset)),
                        );
                      },
                    ),
                    if (!preset.isDefault)
                      IconButton(
                        icon: const Icon(Icons.delete, color: AppTheme.errorColor),
                        onPressed: () {
                          ref.read(compilerProvider.notifier).deletePreset(preset.id);
                        },
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
