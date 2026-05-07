import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../providers/settings_provider.dart';
import '../models/compiler_preset.dart';
import '../theme/theme.dart';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;
import 'package:fluttertoast/fluttertoast.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Row(
            children: [
              _TabBtn(title: 'Compiler', isSelected: _currentIndex == 0, onTap: () => setState(() => _currentIndex = 0)),
              _TabBtn(title: 'Examples', isSelected: _currentIndex == 1, onTap: () => setState(() => _currentIndex = 1)),
            ],
          ),
        ),
      ),
      body: _currentIndex == 0 ? const _CompilerSettings() : const _ExamplesGallery(),
    );
  }
}

class _TabBtn extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabBtn({required this.title, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: isSelected ? AppTheme.primaryColor : Colors.transparent, width: 2)),
          ),
          alignment: Alignment.center,
          child: Text(title, style: TextStyle(color: isSelected ? AppTheme.primaryColor : Colors.white54, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}

class _CompilerSettings extends ConsumerWidget {
  const _CompilerSettings();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SwitchListTile(
          title: const Text('Use Default OneCompiler API'),
          subtitle: const Text('Fastest, recommended for most users'),
          value: state.useDefaultOneCompiler,
          activeTrackColor: AppTheme.primaryColor.withValues(alpha: 0.5),
          activeThumbColor: AppTheme.primaryColor,
          onChanged: (val) => ref.read(settingsProvider.notifier).toggleUseDefault(val),
        ),
        if (!state.useDefaultOneCompiler) ...[
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Custom Presets', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add_circle, color: AppTheme.primaryColor),
                onPressed: () => _editPreset(context, ref, null),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...state.presets.map((p) => Card(
                color: state.activePresetId == p.id ? AppTheme.surfaceColor.withValues(alpha: 0.8) : AppTheme.surfaceColor,
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: state.activePresetId == p.id ? AppTheme.primaryColor : Colors.transparent),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(p.endpointUrl, maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () {
                    ref.read(settingsProvider.notifier).setActivePreset(p.id);
                  },
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => _editPreset(context, ref, p),
                      ),
                      if (!p.isDefault)
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20, color: AppTheme.errorColor),
                          onPressed: () => ref.read(settingsProvider.notifier).deletePreset(p.id),
                        ),
                    ],
                  ),
                ),
              )),
        ]
      ],
    );
  }

  void _editPreset(BuildContext context, WidgetRef ref, CompilerPreset? preset) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => PresetEditor(preset: preset)));
  }
}

class PresetEditor extends ConsumerStatefulWidget {
  final CompilerPreset? preset;
  const PresetEditor({super.key, this.preset});

  @override
  ConsumerState<PresetEditor> createState() => _PresetEditorState();
}

class _PresetEditorState extends ConsumerState<PresetEditor> {
  late TextEditingController _nameCtrl;
  late TextEditingController _urlCtrl;
  String _method = 'POST';
  String _authType = 'None';
  late TextEditingController _authKeyCtrl;
  late TextEditingController _authValueCtrl;
  late TextEditingController _bodyCtrl;
  late TextEditingController _stdoutCtrl;
  late TextEditingController _stderrCtrl;
  late TextEditingController _errorCtrl;
  late TextEditingController _timeCtrl;
  late TextEditingController _memoryCtrl;

  List<MapEntry<String, String>> _headers = [];
  List<MapEntry<String, String>> _queryParams = [];

  final List<String> _methods = ['POST', 'GET', 'PUT'];
  final List<String> _authTypes = ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param'];

  @override
  void initState() {
    super.initState();
    final p = widget.preset;
    _nameCtrl = TextEditingController(text: p?.name ?? 'New Preset');
    _urlCtrl = TextEditingController(text: p?.endpointUrl ?? '');
    _method = p?.httpMethod ?? 'POST';
    _authType = p?.authType ?? 'None';
    _authKeyCtrl = TextEditingController(text: p?.authKey ?? '');
    _authValueCtrl = TextEditingController(text: p?.authValue ?? '');
    _bodyCtrl = TextEditingController(text: p?.requestBodyTemplate ?? '{\n  "code": "{code}"\n}');
    _stdoutCtrl = TextEditingController(text: p?.stdoutPath ?? '');
    _stderrCtrl = TextEditingController(text: p?.stderrPath ?? '');
    _errorCtrl = TextEditingController(text: p?.errorPath ?? '');
    _timeCtrl = TextEditingController(text: p?.executionTimePath ?? '');
    _memoryCtrl = TextEditingController(text: p?.memoryPath ?? '');

    if (p != null) {
      _headers = List.from(p.headers);
      _queryParams = List.from(p.queryParams);
    }
  }

  void _save() {
    final p = CompilerPreset(
      id: widget.preset?.id ?? const Uuid().v4(),
      name: _nameCtrl.text,
      endpointUrl: _urlCtrl.text,
      httpMethod: _method,
      authType: _authType,
      authKey: _authKeyCtrl.text,
      authValue: _authValueCtrl.text,
      headers: _headers.where((e) => e.key.isNotEmpty).toList(),
      queryParams: _queryParams.where((e) => e.key.isNotEmpty).toList(),
      requestBodyTemplate: _bodyCtrl.text,
      stdoutPath: _stdoutCtrl.text,
      stderrPath: _stderrCtrl.text,
      errorPath: _errorCtrl.text,
      executionTimePath: _timeCtrl.text,
      memoryPath: _memoryCtrl.text,
      isDefault: widget.preset?.isDefault ?? false,
    );

    if (widget.preset == null) {
      ref.read(settingsProvider.notifier).addPreset(p);
    } else {
      ref.read(settingsProvider.notifier).updatePreset(p);
    }
    Navigator.pop(context);
  }

  void _testConnection() async {
     Fluttertoast.showToast(msg: "Testing connection...");
     // Using the logic from ExecutionProvider to test locally here
     try {
        final p = CompilerPreset(
          name: _nameCtrl.text,
          endpointUrl: _urlCtrl.text,
          httpMethod: _method,
          authType: _authType,
          authKey: _authKeyCtrl.text,
          authValue: _authValueCtrl.text,
          headers: _headers,
          queryParams: _queryParams,
          requestBodyTemplate: _bodyCtrl.text,
          stdoutPath: _stdoutCtrl.text,
          stderrPath: _stderrCtrl.text,
          errorPath: _errorCtrl.text,
          executionTimePath: _timeCtrl.text,
          memoryPath: _memoryCtrl.text,
        );

        final uri = Uri.parse(p.endpointUrl);
        Map<String, String> hdrs = {};
        for (var h in p.headers) {
          if (h.key.isNotEmpty) hdrs[h.key] = h.value;
        }
        if (p.authType == 'API-Key Header' && p.authKey.isNotEmpty) {
          hdrs[p.authKey] = p.authValue;
        } else if (p.authType == 'Bearer Token') {
          hdrs['Authorization'] = 'Bearer \${p.authValue}';
        } else if (p.authType == 'Basic Auth') {
           final encoded = base64Encode(utf8.encode(p.authValue));
           hdrs['Authorization'] = 'Basic $encoded';
        }

        Map<String, String> qParams = {};
        for (var q in p.queryParams) {
           if (q.key.isNotEmpty) qParams[q.key] = q.value;
        }
        if (p.authType == 'Query Param' && p.authKey.isNotEmpty) {
           qParams[p.authKey] = p.authValue;
        }

        final requestUri = qParams.isNotEmpty ? uri.replace(queryParameters: qParams) : uri;

        String body = p.requestBodyTemplate;
        String encodedCode = jsonEncode("void main() { print('Hello from Custom API'); }");
        encodedCode = encodedCode.substring(1, encodedCode.length - 1);
        body = body.replaceAll('{code}', encodedCode).replaceAll('{stdin}', '').replaceAll('{language}', 'dart');

        http.Response response;
        if (p.httpMethod.toUpperCase() == 'GET') {
          response = await http.get(requestUri, headers: hdrs);
        } else if (p.httpMethod.toUpperCase() == 'PUT') {
          response = await http.put(requestUri, headers: hdrs, body: body);
        } else {
          response = await http.post(requestUri, headers: hdrs, body: body);
        }

        if (!mounted) return;
        showDialog(context: context, builder: (BuildContext context) {
          // ignore: prefer_const_constructors
          return AlertDialog(
            // ignore: prefer_const_constructors
            title: Text('Status: \${response.statusCode}'),
            // ignore: prefer_const_constructors
            content: SingleChildScrollView(child: Text(response.body)),
            actions: <Widget>[TextButton(onPressed: ()=>Navigator.pop(context), child: const Text('OK'))],
          );
        });
     } catch (e) {
        Fluttertoast.showToast(msg: "Error: \$e");
     }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Preset'),
        actions: [
          IconButton(icon: const Icon(Icons.play_circle_fill, color: AppTheme.successColor), onPressed: _testConnection),
          IconButton(icon: const Icon(Icons.save, color: AppTheme.primaryColor), onPressed: _save),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Preset Name')),
          const SizedBox(height: 12),
          TextField(controller: _urlCtrl, decoration: const InputDecoration(labelText: 'Endpoint URL')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _method,
            decoration: const InputDecoration(labelText: 'HTTP Method'),
            items: _methods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
            onChanged: (v) => setState(() => _method = v!),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _authType,
            decoration: const InputDecoration(labelText: 'Auth Type'),
            items: _authTypes.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
            onChanged: (v) => setState(() => _authType = v!),
          ),
          if (_authType != 'None' && _authType != 'Bearer Token' && _authType != 'Basic Auth') ...[
            const SizedBox(height: 12),
            TextField(controller: _authKeyCtrl, decoration: const InputDecoration(labelText: 'Auth Key (e.g. X-API-Key)')),
          ],
          if (_authType != 'None') ...[
            const SizedBox(height: 12),
            TextField(controller: _authValueCtrl, decoration: const InputDecoration(labelText: 'Auth Value (Token/Secret)')),
          ],
          const SizedBox(height: 24),
          const Text('Headers', style: TextStyle(fontWeight: FontWeight.bold)),
          ..._headers.asMap().entries.map((e) => Row(
            children: [
              Expanded(child: TextFormField(initialValue: e.value.key, onChanged: (v) => _headers[e.key] = MapEntry(v, e.value.value), decoration: const InputDecoration(hintText: 'Key'))),
              const SizedBox(width: 8),
              Expanded(child: TextFormField(initialValue: e.value.value, onChanged: (v) => _headers[e.key] = MapEntry(e.value.key, v), decoration: const InputDecoration(hintText: 'Value'))),
              IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red), onPressed: () => setState(() => _headers.removeAt(e.key))),
            ],
          )),
          TextButton.icon(onPressed: () => setState(() => _headers.add(const MapEntry('', ''))), icon: const Icon(Icons.add), label: const Text('Add Header')),

          const SizedBox(height: 24),
          const Text('Body Template (JSON)', style: TextStyle(fontWeight: FontWeight.bold)),
          const Text('Use {code}, {stdin}, {language}', style: TextStyle(fontSize: 12, color: Colors.white54)),
          const SizedBox(height: 8),
          TextField(controller: _bodyCtrl, maxLines: 6, decoration: const InputDecoration(hintText: '{\n  "code": "{code}"\n}')),

          const SizedBox(height: 24),
          const Text('Response Mapping (Dot notation)', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(controller: _stdoutCtrl, decoration: const InputDecoration(labelText: 'Stdout Path (e.g. data.output)')),
          const SizedBox(height: 8),
          TextField(controller: _stderrCtrl, decoration: const InputDecoration(labelText: 'Stderr Path')),
          const SizedBox(height: 8),
          TextField(controller: _errorCtrl, decoration: const InputDecoration(labelText: 'Error Path')),
          const SizedBox(height: 8),
          TextField(controller: _timeCtrl, decoration: const InputDecoration(labelText: 'Execution Time Path')),
        ],
      ),
    );
  }
}

class _ExamplesGallery extends StatelessWidget {
  const _ExamplesGallery();

  final String _examplesMarkdown = '''
# DartMini Examples

## 1. Hello World
```dart
void main() {
  print('Hello, World!');
}
```

## 2. Using Stdin
```dart
import 'dart:io';

void main() {
  print("Enter your name:");
  String? name = stdin.readLineSync();
  print("Hello, \$name!");
}
```

## 3. Async / Await
```dart
void main() async {
  print('Fetching data...');
  await Future.delayed(Duration(seconds: 1));
  print('Data loaded!');
}
```
  ''';

  @override
  Widget build(BuildContext context) {
    return Markdown(
      data: _examplesMarkdown,
      styleSheet: MarkdownStyleSheet(
        h1: const TextStyle(color: AppTheme.primaryColor),
        h2: const TextStyle(color: Colors.white),
        codeblockDecoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
