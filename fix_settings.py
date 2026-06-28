with open("dartmini_ide/lib/ui/settings_screen.dart", "r") as f:
    lines = f.readlines()

new_lines = []
for line in lines:
    new_lines.append(line)
    if "import 'package:fluttertoast/fluttertoast.dart';" in line:
        new_lines.append("import 'package:file_picker/file_picker.dart';\n")
        new_lines.append("import 'dart:io';\n")

    if "_buildGeneralTab() {" in line:
        pass # just checking for injection point below

    # we will inject after switch list tile in general tab
    if "}," in line and "toggleUseOneCompiler(val);" in "".join(lines): # very loose check, let's do it better
        pass

# Since doing line by line is error prone, let's just do a string replace
with open("dartmini_ide/lib/ui/settings_screen.dart", "r") as f:
    content = f.read()

content = content.replace("import 'package:fluttertoast/fluttertoast.dart';", "import 'package:fluttertoast/fluttertoast.dart';\nimport 'package:file_picker/file_picker.dart';\nimport 'dart:io';")

general_tab_replacement = """
  Widget _buildGeneralTab() {
    final compilerState = ref.watch(compilerProvider);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SwitchListTile(
          title: const Text('Use Default OneCompiler API', style: TextStyle(color: Colors.white)),
          subtitle: const Text('Fast & reliable default execution', style: TextStyle(color: Colors.white54)),
          value: compilerState.useOneCompiler,
          // ignore: deprecated_member_use
          activeColor: AppTheme.primaryAccent,
          onChanged: (val) {
            ref.read(compilerProvider.notifier).toggleUseOneCompiler(val);
          },
        ),
        const SizedBox(height: 24),
        const Divider(color: Colors.white24),
        const SizedBox(height: 16),
        const Text('Backup & Restore', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () async {
             // Export presets
             final presets = ref.read(compilerProvider).presets;
             final list = presets.map((p) => {
               'name': p.name,
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
             }).toList();

             final jsonStr = jsonEncode(list);

             try {
                String? outputFile = await FilePicker.platform.saveFile(
                  dialogTitle: 'Export Presets',
                  fileName: 'dartmini_presets.json',
                );

                if (outputFile != null) {
                   File file = File(outputFile);
                   await file.writeAsString(jsonStr);
                   Fluttertoast.showToast(msg: "Presets exported successfully");
                }
             } catch (e) {
                Fluttertoast.showToast(msg: "Error exporting presets: $e");
             }
          },
          icon: const Icon(Icons.upload_file),
          label: const Text('Export Presets to JSON'),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () async {
            // Import presets
             FilePickerResult? result = await FilePicker.platform.pickFiles(
                type: FileType.custom,
                allowedExtensions: ['json'],
                withData: true,
              );
              if (result != null) {
                try {
                  final file = result.files.first;
                  final content = utf8.decode(file.bytes!);
                  final List<dynamic> jsonList = jsonDecode(content);

                  for (var item in jsonList) {
                    final preset = CompilerPreset(
                       name: item['name'] ?? 'Imported Preset',
                       endpointUrl: item['endpointUrl'] ?? '',
                       httpMethod: item['httpMethod'] ?? 'POST',
                       authType: item['authType'] ?? 'None',
                       headers: Map<String, String>.from(item['headers'] ?? {}),
                       queryParams: Map<String, String>.from(item['queryParams'] ?? {}),
                       requestBodyTemplate: item['requestBodyTemplate'] ?? '',
                       stdoutPath: item['stdoutPath'] ?? '',
                       stderrPath: item['stderrPath'] ?? '',
                       errorPath: item['errorPath'] ?? '',
                       executionTimePath: item['executionTimePath'] ?? '',
                       memoryPath: item['memoryPath'] ?? '',
                    );
                    ref.read(compilerProvider.notifier).addPreset(preset);
                  }

                  Fluttertoast.showToast(msg: "Imported ${jsonList.length} presets");
                } catch(e) {
                  Fluttertoast.showToast(msg: "Failed to parse JSON presets");
                }
              }
          },
          icon: const Icon(Icons.download),
          label: const Text('Import Presets from JSON'),
        ),
      ],
    );
  }
"""

import re
content = re.sub(r'Widget _buildGeneralTab\(\) \{.*?\n  \}', general_tab_replacement, content, flags=re.DOTALL)

with open("dartmini_ide/lib/ui/settings_screen.dart", "w") as f:
    f.write(content)
