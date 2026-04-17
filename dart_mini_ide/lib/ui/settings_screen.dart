import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../models/compiler_preset.dart';
import '../providers/compiler_provider.dart';
import '../providers/execution_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(compilerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Use Default OneCompiler', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Bypass custom presets and use rapidAPI key', style: TextStyle(color: Colors.grey)),
            value: state.useDefaultOneCompiler,
            activeTrackColor: const Color(0xFFFACC15),
            onChanged: (val) {
              ref.read(compilerProvider.notifier).toggleUseDefault(val);
            },
          ),
          const Divider(color: Colors.white24, height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Compiler Presets', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add, color: Color(0xFFFACC15)),
                onPressed: () => _openPresetForm(context, ref, null),
              )
            ],
          ),
          const SizedBox(height: 16),
          ...state.presets.map((p) {
            final isActive = p.id == state.activePresetId && !state.useDefaultOneCompiler;
            return Card(
              color: const Color(0xFF1a1a1a),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: isActive ? const Color(0xFFFACC15) : Colors.transparent, width: 2),
              ),
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(p.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text(p.endpointUrl, style: const TextStyle(color: Colors.grey, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!p.isReadOnly)
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 20),
                        onPressed: () => _openPresetForm(context, ref, p),
                      ),
                    IconButton(
                      icon: const Icon(Icons.copy, color: Colors.greenAccent, size: 20),
                      onPressed: () {
                        ref.read(compilerProvider.notifier).duplicatePreset(p);
                        Fluttertoast.showToast(msg: "Preset duplicated", backgroundColor: Colors.grey[900]);
                      },
                    ),
                    if (!p.isReadOnly)
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                        onPressed: () {
                           ref.read(compilerProvider.notifier).deletePreset(p.id);
                           Fluttertoast.showToast(msg: "Preset deleted", backgroundColor: Colors.grey[900]);
                        },
                      ),
                  ],
                ),
                onTap: () {
                  ref.read(compilerProvider.notifier).setActivePreset(p.id);
                  ref.read(compilerProvider.notifier).toggleUseDefault(false);
                },
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  void _openPresetForm(BuildContext context, WidgetRef ref, CompilerPreset? preset) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => PresetFormScreen(preset: preset)));
  }
}

class PresetFormScreen extends ConsumerStatefulWidget {
  final CompilerPreset? preset;
  const PresetFormScreen({Key? key, this.preset}) : super(key: key);

  @override
  ConsumerState<PresetFormScreen> createState() => _PresetFormScreenState();
}

class _PresetFormScreenState extends ConsumerState<PresetFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name, _endpointUrl, _httpMethod, _authType, _authValue;
  late String _requestBodyTemplate, _stdoutPath, _stderrPath, _errorPath, _timePath, _memoryPath;
  List<MapEntry<String, String>> _headers = [];
  List<MapEntry<String, String>> _queryParams = [];

  @override
  void initState() {
    super.initState();
    final p = widget.preset;
    _name = p?.name ?? 'New Preset';
    _endpointUrl = p?.endpointUrl ?? '';
    _httpMethod = p?.httpMethod ?? 'POST';
    _authType = p?.authType ?? 'None';
    _authValue = p?.authValue ?? '';
    _requestBodyTemplate = p?.requestBodyTemplate ?? '';
    _stdoutPath = p?.stdoutPath ?? '';
    _stderrPath = p?.stderrPath ?? '';
    _errorPath = p?.errorPath ?? '';
    _timePath = p?.executionTimePath ?? '';
    _memoryPath = p?.memoryPath ?? '';

    if (p != null) {
      _headers = p.headers.entries.toList();
      _queryParams = p.queryParams.entries.toList();
    }
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final Map<String, String> hdrs = {for (var e in _headers) e.key: e.value};
      final Map<String, String> qp = {for (var e in _queryParams) e.key: e.value};

      final newPreset = CompilerPreset(
        id: widget.preset?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _name,
        endpointUrl: _endpointUrl,
        httpMethod: _httpMethod,
        authType: _authType,
        authValue: _authValue,
        headers: hdrs,
        queryParams: qp,
        requestBodyTemplate: _requestBodyTemplate,
        stdoutPath: _stdoutPath,
        stderrPath: _stderrPath,
        errorPath: _errorPath,
        executionTimePath: _timePath,
        memoryPath: _memoryPath,
        isReadOnly: false,
      );

      ref.read(compilerProvider.notifier).savePreset(newPreset);
      Navigator.pop(context);
    }
  }

  Future<void> _testConnection() async {
    _formKey.currentState?.save();

    final Map<String, String> hdrs = {for (var e in _headers) e.key: e.value};
    final Map<String, String> qp = {for (var e in _queryParams) e.key: e.value};

    final tempPreset = CompilerPreset(
        id: 'test',
        name: 'test',
        endpointUrl: _endpointUrl,
        httpMethod: _httpMethod,
        authType: _authType,
        authValue: _authValue,
        headers: hdrs,
        queryParams: qp,
        requestBodyTemplate: _requestBodyTemplate,
        stdoutPath: _stdoutPath,
        stderrPath: _stderrPath,
        errorPath: _errorPath,
        executionTimePath: _timePath,
        memoryPath: _memoryPath,
    );

    Fluttertoast.showToast(msg: "Testing connection...", backgroundColor: Colors.grey[900]);

    final service = ref.read(executionServiceProvider);
    final result = await service.executeCustom("void main() { print('Hello from Custom API'); }", tempPreset);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a1a),
        title: const Text('Test Result', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Stdout: ${result.stdout}', style: const TextStyle(color: Colors.greenAccent)),
              Text('Stderr: ${result.stderr}', style: const TextStyle(color: Colors.redAccent)),
              Text('Error: ${result.error}', style: const TextStyle(color: Colors.redAccent)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))
        ],
      ),
    );
  }

  Widget _buildTextField(String label, String initialValue, Function(String?) onSave, {int lines = 1, bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        initialValue: initialValue,
        style: const TextStyle(color: Colors.white),
        maxLines: lines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
          focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFFACC15))),
        ),
        validator: required ? (v) => v == null || v.isEmpty ? 'Required' : null : null,
        onSaved: (v) => onSave(v),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(widget.preset == null ? 'New Preset' : 'Edit Preset', style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(icon: const Icon(Icons.play_arrow, color: Color(0xFFFACC15)), onPressed: _testConnection, tooltip: 'Test Connection'),
          IconButton(icon: const Icon(Icons.save, color: Colors.blueAccent), onPressed: _save),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildTextField('Preset Name', _name, (v) => _name = v ?? '', required: true),
            _buildTextField('Endpoint URL', _endpointUrl, (v) => _endpointUrl = v ?? '', required: true),
            DropdownButtonFormField<String>(
              dropdownColor: const Color(0xFF1a1a1a),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'HTTP Method',
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              ),
              initialValue: _httpMethod,
              items: ['POST', 'GET', 'PUT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _httpMethod = v ?? 'POST'),
              onSaved: (v) => _httpMethod = v ?? 'POST',
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              dropdownColor: const Color(0xFF1a1a1a),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Auth Type',
                labelStyle: TextStyle(color: Colors.grey),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              ),
              initialValue: _authType,
              items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _authType = v ?? 'None'),
              onSaved: (v) => _authType = v ?? 'None',
            ),
            const SizedBox(height: 16),
            if (_authType != 'None')
              _buildTextField('Auth Value (e.g. HeaderKey:Value or Token)', _authValue, (v) => _authValue = v ?? ''),

            const Divider(color: Colors.white24, height: 32),
            const Text('Headers', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ..._headers.asMap().entries.map((e) {
               int idx = e.key;
               return Row(
                 children: [
                   Expanded(child: TextFormField(
                     initialValue: e.value.key,
                     style: const TextStyle(color: Colors.white),
                     decoration: const InputDecoration(hintText: 'Key', hintStyle: TextStyle(color: Colors.grey)),
                     onChanged: (v) => _headers[idx] = MapEntry(v, _headers[idx].value),
                   )),
                   const SizedBox(width: 8),
                   Expanded(child: TextFormField(
                     initialValue: e.value.value,
                     style: const TextStyle(color: Colors.white),
                     decoration: const InputDecoration(hintText: 'Value', hintStyle: TextStyle(color: Colors.grey)),
                     onChanged: (v) => _headers[idx] = MapEntry(_headers[idx].key, v),
                   )),
                   IconButton(icon: const Icon(Icons.remove_circle, color: Colors.redAccent), onPressed: () => setState(() => _headers.removeAt(idx)))
                 ],
               );
            }).toList(),
            TextButton.icon(
              onPressed: () => setState(() => _headers.add(const MapEntry('', ''))),
              icon: const Icon(Icons.add, color: Color(0xFFFACC15)),
              label: const Text('Add Header', style: TextStyle(color: Color(0xFFFACC15))),
            ),

            const Divider(color: Colors.white24, height: 32),
            const Text('Request Body Template (JSON)', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const Text('Use {code}, {language}, {stdin}', style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 8),
            _buildTextField('Body', _requestBodyTemplate, (v) => _requestBodyTemplate = v ?? '', lines: 6),

            const Divider(color: Colors.white24, height: 32),
            const Text('Response Mapping (Dot Notation)', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildTextField('Stdout Path (e.g. data.output)', _stdoutPath, (v) => _stdoutPath = v ?? ''),
            _buildTextField('Stderr Path', _stderrPath, (v) => _stderrPath = v ?? ''),
            _buildTextField('Error Path', _errorPath, (v) => _errorPath = v ?? ''),
            _buildTextField('Execution Time Path', _timePath, (v) => _timePath = v ?? ''),
            _buildTextField('Memory Path', _memoryPath, (v) => _memoryPath = v ?? ''),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
