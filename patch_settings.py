import re
with open('dart_mini_ide/lib/ui/settings_screen.dart', 'r') as f:
    content = f.read()

import_block = """                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PresetEditorScreen(preset: null),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add, color: Colors.black, size: 18),
                    label: const Text('Add New', style: TextStyle(color: Colors.black)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFACC15),
                    ),
                  )
"""

new_buttons = """                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.file_upload),
                        tooltip: 'Export Presets',
                        onPressed: () async {
                          final presetsStr = jsonEncode(presets.map((e) => e.toJson()).toList());
                          await FileService.downloadFile('dart_mini_presets.json', presetsStr);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.file_download),
                        tooltip: 'Import Presets',
                        onPressed: () async {
                          final result = await FileService.importFile();
                          if (result != null) {
                            try {
                              final List<dynamic> decoded = jsonDecode(result['content']!);
                              final newPresets = decoded.map((e) => CompilerPreset.fromJson(e)).toList();
                              ref.read(presetProvider.notifier).importPresetsFromJson(newPresets);
                              Fluttertoast.showToast(msg: 'Presets imported successfully!');
                            } catch (e) {
                              Fluttertoast.showToast(msg: 'Invalid JSON format');
                            }
                          }
                        },
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PresetEditorScreen(preset: null),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add, color: Colors.black, size: 18),
                        label: const Text('Add New', style: TextStyle(color: Colors.black)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFACC15),
                        ),
                      ),
                    ],
                  )"""

content = content.replace(import_block, new_buttons)

imports = "import 'preset_editor.dart';\nimport 'dart:convert';\nimport '../services/file_service.dart';\nimport 'package:fluttertoast/fluttertoast.dart';\nimport '../models/models.dart';\n"
content = content.replace("import 'preset_editor.dart';", imports)

with open('dart_mini_ide/lib/ui/settings_screen.dart', 'w') as f:
    f.write(content)
