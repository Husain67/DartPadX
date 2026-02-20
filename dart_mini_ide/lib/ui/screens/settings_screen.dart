import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../core/constants.dart';
import '../../providers/settings_provider.dart';
import '../../providers/execution_provider.dart';
import '../../data/models/compiler_preset.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final presets = ref.watch(settingsProvider);
    final activePresetId = ref.watch(activePresetIdProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("Compiler Presets", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppConstants.primaryColor)),
          ),
          ...presets.map((preset) => ListTile(
            title: Text(preset.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(preset.endpointUrl, maxLines: 1, overflow: TextOverflow.ellipsis),
            leading: Radio<String>(
              value: preset.id,
              groupValue: activePresetId,
              onChanged: (val) {
                if (val != null) {
                  ref.read(activePresetIdProvider.notifier).state = val;
                }
              },
              activeColor: AppConstants.primaryColor,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blueAccent),
                  onPressed: () {
                     Navigator.push(context, MaterialPageRoute(builder: (_) => PresetEditorScreen(preset: preset)));
                  },
                ),
                if (!preset.isDefault)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.redAccent),
                    onPressed: () {
                      if (preset.id == activePresetId) {
                         Fluttertoast.showToast(msg: "Cannot delete active preset");
                         return;
                      }
                      ref.read(settingsProvider.notifier).deletePreset(preset.id);
                    },
                  ),
              ],
            ),
          )),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () {
                 Navigator.push(context, MaterialPageRoute(builder: (_) => const PresetEditorScreen()));
              },
              icon: const Icon(Icons.add, color: Colors.black),
              label: const Text("Add Custom Compiler", style: TextStyle(color: Colors.black)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PresetEditorScreen extends ConsumerStatefulWidget {
  final CompilerPreset? preset;
  const PresetEditorScreen({Key? key, this.preset}) : super(key: key);

  @override
  ConsumerState<PresetEditorScreen> createState() => _PresetEditorScreenState();
}

class _PresetEditorScreenState extends ConsumerState<PresetEditorScreen> {
  late TextEditingController _nameController;
  late TextEditingController _urlController;
  late TextEditingController _methodController;
  late TextEditingController _bodyController;

  late TextEditingController _stdoutController;
  late TextEditingController _stderrController;
  late TextEditingController _errorController;
  late TextEditingController _timeController;
  late TextEditingController _memoryController;

  Map<String, String> _headers = {};
  Map<String, String> _queryParams = {};

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.preset?.name ?? 'New Preset');
    _urlController = TextEditingController(text: widget.preset?.endpointUrl ?? 'https://api.onecompiler.com/api/v1/run');
    _methodController = TextEditingController(text: widget.preset?.httpMethod ?? 'POST');
    _bodyController = TextEditingController(text: widget.preset?.requestBodyTemplate ?? '{\n  "language": "dart",\n  "stdin": "{stdin}",\n  "files": [\n    {\n      "name": "main.dart",\n      "content": "{code}"\n    }\n  ]\n}');

    _stdoutController = TextEditingController(text: widget.preset?.stdoutPath ?? 'stdout');
    _stderrController = TextEditingController(text: widget.preset?.stderrPath ?? 'stderr');
    _errorController = TextEditingController(text: widget.preset?.errorPath ?? 'exception');
    _timeController = TextEditingController(text: widget.preset?.executionTimePath ?? 'executionTime');
    _memoryController = TextEditingController(text: widget.preset?.memoryPath ?? 'memory');

    if (widget.preset != null) {
      _headers = Map.from(widget.preset!.headers);
      _queryParams = Map.from(widget.preset!.queryParams);
    } else {
      // Default headers
      _headers = {'Content-Type': 'application/json'};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.preset == null ? "New Preset" : "Edit Preset"),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _save,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader("Basic Info"),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Preset Name", border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: "Endpoint URL",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                     Clipboard.setData(ClipboardData(text: _urlController.text));
                     Fluttertoast.showToast(msg: "URL Copied");
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextField(controller: _methodController, decoration: const InputDecoration(labelText: "HTTP Method (POST, GET, PUT)", border: OutlineInputBorder())),

            const SizedBox(height: 20),
            _buildSectionHeader("Headers"),
            _buildKeyValueList(_headers),

            const SizedBox(height: 20),
            _buildSectionHeader("Query Params"),
            _buildKeyValueList(_queryParams),

            const SizedBox(height: 20),
            _buildSectionHeader("Request Body Template"),
            const Text("Use {code}, {stdin}, {language} as placeholders.", style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 5),
            TextField(
              controller: _bodyController,
              maxLines: 8,
              style: const TextStyle(fontFamily: 'monospace'),
              decoration: const InputDecoration(border: OutlineInputBorder(), filled: true, fillColor: Color(0xFF1E1E1E)),
            ),

            const SizedBox(height: 20),
            _buildSectionHeader("Response Mapping (JSON Path)"),
            _buildMappingField("Stdout Path", _stdoutController),
            _buildMappingField("Stderr Path", _stderrController),
            _buildMappingField("Error Path", _errorController),
            _buildMappingField("Execution Time Path", _timeController),
            _buildMappingField("Memory Path", _memoryController),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _testConnection,
                child: const Text("Save & Test Connection"),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppConstants.primaryColor)),
    );
  }

  Widget _buildMappingField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TextField(controller: controller, decoration: InputDecoration(labelText: label, isDense: true, border: const OutlineInputBorder())),
    );
  }

  Widget _buildKeyValueList(Map<String, String> map) {
    return Column(
      children: [
        ...map.entries.map((e) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(e.value, overflow: TextOverflow.ellipsis),
            trailing: IconButton(
              icon: const Icon(Icons.delete, size: 20, color: Colors.red),
              onPressed: () {
                setState(() {
                  map.remove(e.key);
                });
              },
            ),
          ),
        )),
        OutlinedButton.icon(
          onPressed: () {
            _showAddEntryDialog(map);
          },
          icon: const Icon(Icons.add),
          label: const Text("Add Entry"),
        ),
      ],
    );
  }

  void _showAddEntryDialog(Map<String, String> map) {
    String key = '';
    String value = '';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Add Entry"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(decoration: const InputDecoration(labelText: "Key"), onChanged: (v) => key = v),
            TextField(decoration: const InputDecoration(labelText: "Value"), onChanged: (v) => value = v),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () {
               if (key.isNotEmpty) {
                 setState(() {
                    map[key] = value;
                 });
               }
               Navigator.pop(ctx);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _save() {
     final newPreset = _buildPreset();
     ref.read(settingsProvider.notifier).addPreset(newPreset);
     Navigator.pop(context);
  }

  CompilerPreset _buildPreset() {
    return CompilerPreset(
        id: widget.preset?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.isEmpty ? 'Untitled' : _nameController.text,
        endpointUrl: _urlController.text,
        httpMethod: _methodController.text,
        authType: widget.preset?.authType ?? 'None',
        headers: _headers,
        queryParams: _queryParams,
        requestBodyTemplate: _bodyController.text,
        stdoutPath: _stdoutController.text,
        stderrPath: _stderrController.text,
        errorPath: _errorController.text,
        executionTimePath: _timeController.text,
        memoryPath: _memoryController.text,
        isDefault: false,
     );
  }

  Future<void> _testConnection() async {
    // 1. Save preset
    final newPreset = _buildPreset();
    ref.read(settingsProvider.notifier).addPreset(newPreset);

    // 2. Set as active
    ref.read(activePresetIdProvider.notifier).state = newPreset.id;

    // 3. Run test code
    Fluttertoast.showToast(msg: "Testing connection...");
    await ref.read(executionProvider).runCode("void main() { print('Connection Successful!'); }", "");

    // 4. Show result
    final result = ref.read(executionResultProvider);
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(result?.isSuccess == true ? 'Success' : 'Failed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (result?.stdout.isNotEmpty == true) Text("Stdout: ${result?.stdout}"),
            if (result?.stderr.isNotEmpty == true) Text("Stderr: ${result?.stderr}"),
            if (result?.error.isNotEmpty == true) Text("Error: ${result?.error}", style: const TextStyle(color: Colors.red)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }
}
