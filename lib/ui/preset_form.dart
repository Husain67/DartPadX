
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../providers/providers.dart';
import '../models/models.dart';

class PresetForm extends ConsumerStatefulWidget {
  final String? presetId;

  const PresetForm({super.key, this.presetId});

  @override
  ConsumerState<PresetForm> createState() => _PresetFormState();
}

class _PresetFormState extends ConsumerState<PresetForm> {
  final _formKey = GlobalKey<FormState>();

  late String _id;
  late TextEditingController _nameCtrl;
  late TextEditingController _urlCtrl;
  String _method = 'POST';
  String _authType = 'None';
  late TextEditingController _authKeyCtrl;
  late TextEditingController _authValueCtrl;

  List<MapEntry<String, String>> _headers = [];
  List<MapEntry<String, String>> _queryParams = [];

  late TextEditingController _bodyTemplateCtrl;
  late TextEditingController _stdoutCtrl;
  late TextEditingController _stderrCtrl;
  late TextEditingController _errorCtrl;
  late TextEditingController _timeCtrl;
  late TextEditingController _memoryCtrl;

  @override
  void initState() {
    super.initState();
    _id = widget.presetId ?? const Uuid().v4();

    CompilerPreset? existing;
    if (widget.presetId != null) {
      existing = ref.read(settingsProvider).presets.firstWhere((p) => p.id == widget.presetId);
    }

    _nameCtrl = TextEditingController(text: existing?.name ?? 'New Preset');
    _urlCtrl = TextEditingController(text: existing?.endpointUrl ?? '');
    _method = existing?.method ?? 'POST';
    _authType = existing?.authType ?? 'None';
    _authKeyCtrl = TextEditingController(text: existing?.authKey ?? '');
    _authValueCtrl = TextEditingController(text: existing?.authValue ?? '');

    if (existing != null) {
      _headers = existing.headers.entries.toList();
      _queryParams = existing.queryParams.entries.toList();
    }

    _bodyTemplateCtrl = TextEditingController(text: existing?.bodyTemplate ?? '{}');
    _stdoutCtrl = TextEditingController(text: existing?.stdoutPath ?? '');
    _stderrCtrl = TextEditingController(text: existing?.stderrPath ?? '');
    _errorCtrl = TextEditingController(text: existing?.errorPath ?? '');
    _timeCtrl = TextEditingController(text: existing?.executionTimePath ?? '');
    _memoryCtrl = TextEditingController(text: existing?.memoryPath ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _urlCtrl.dispose();
    _authKeyCtrl.dispose();
    _authValueCtrl.dispose();
    _bodyTemplateCtrl.dispose();
    _stdoutCtrl.dispose();
    _stderrCtrl.dispose();
    _errorCtrl.dispose();
    _timeCtrl.dispose();
    _memoryCtrl.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final headersMap = Map.fromEntries(_headers.where((e) => e.key.isNotEmpty));
      final queryMap = Map.fromEntries(_queryParams.where((e) => e.key.isNotEmpty));

      final preset = CompilerPreset(
        id: _id,
        name: _nameCtrl.text,
        endpointUrl: _urlCtrl.text,
        method: _method,
        authType: _authType,
        authKey: _authKeyCtrl.text,
        authValue: _authValueCtrl.text,
        headers: headersMap,
        queryParams: queryMap,
        bodyTemplate: _bodyTemplateCtrl.text,
        stdoutPath: _stdoutCtrl.text,
        stderrPath: _stderrCtrl.text,
        errorPath: _errorCtrl.text,
        executionTimePath: _timeCtrl.text,
        memoryPath: _memoryCtrl.text,
      );

      ref.read(settingsProvider.notifier).savePreset(preset);
      Navigator.pop(context);
    }
  }

  void _testConnection() async {
      // Create temporary preset from current form data
      final headersMap = Map.fromEntries(_headers.where((e) => e.key.isNotEmpty));
      final queryMap = Map.fromEntries(_queryParams.where((e) => e.key.isNotEmpty));
      final tempPreset = CompilerPreset(
        id: 'test',
        name: 'test',
        endpointUrl: _urlCtrl.text,
        method: _method,
        authType: _authType,
        authKey: _authKeyCtrl.text,
        authValue: _authValueCtrl.text,
        headers: headersMap,
        queryParams: queryMap,
        bodyTemplate: _bodyTemplateCtrl.text,
        stdoutPath: _stdoutCtrl.text,
        stderrPath: _stderrCtrl.text,
        errorPath: _errorCtrl.text,
        executionTimePath: _timeCtrl.text,
        memoryPath: _memoryCtrl.text,
      );

      Fluttertoast.showToast(msg: "Testing connection...");
      await ref.read(executionProvider.notifier).executeCode("void main() { print('Hello from custom API'); }", tempPreset);

      final execState = ref.read(executionProvider);

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
                const Text('Stdout:', style: TextStyle(color: Color(0xFFFACC15))),
                Text(execState.stdout, style: const TextStyle(color: Colors.green)),
                const SizedBox(height: 8),
                const Text('Stderr / Error:', style: TextStyle(color: Color(0xFFFACC15))),
                Text(execState.stderr, style: const TextStyle(color: Colors.red)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close', style: TextStyle(color: Colors.white)),
            )
          ],
        )
      );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1, bool required = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          border: const OutlineInputBorder(),
          enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF333333))),
          focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFFFACC15))),
        ),
        validator: required ? (val) => val == null || val.isEmpty ? 'Required' : null : null,
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        dropdownColor: const Color(0xFF1a1a1a),
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          border: const OutlineInputBorder(),
          enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF333333))),
        ),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDynamicList(String title, List<MapEntry<String, String>> list, VoidCallback onAdd, Function(int) onRemove) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(color: Color(0xFFFACC15), fontWeight: FontWeight.bold)),
            IconButton(icon: const Icon(Icons.add, color: Colors.green), onPressed: onAdd),
          ],
        ),
        ...list.asMap().entries.map((entry) {
          int idx = entry.key;
          return Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: entry.value.key,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(hintText: 'Key', hintStyle: TextStyle(color: Colors.grey)),
                  onChanged: (v) => setState(() => list[idx] = MapEntry(v, list[idx].value)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  initialValue: entry.value.value,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(hintText: 'Value', hintStyle: TextStyle(color: Colors.grey)),
                  onChanged: (v) => setState(() => list[idx] = MapEntry(list[idx].key, v)),
                ),
              ),
              IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red), onPressed: () => onRemove(idx)),
            ],
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF050505),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Edit Preset', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.play_circle_outline, color: Colors.green),
            onPressed: _testConnection,
            tooltip: 'Test Connection',
          ),
          IconButton(
            icon: const Icon(Icons.save, color: Color(0xFFFACC15)),
            onPressed: _save,
          )
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildTextField('Preset Name', _nameCtrl, required: true),
            _buildTextField('Endpoint URL', _urlCtrl, required: true),
            Row(
              children: [
                Expanded(child: _buildDropdown('Method', _method, ['POST', 'GET', 'PUT'], (v) => setState(() => _method = v!))),
                const SizedBox(width: 16),
                Expanded(child: _buildDropdown('Auth Type', _authType, ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param'], (v) => setState(() => _authType = v!))),
              ],
            ),
            if (_authType == 'API-Key Header' || _authType == 'Query Param')
               _buildTextField('Auth Key (e.g. X-API-Key)', _authKeyCtrl),
            if (_authType != 'None')
               _buildTextField('Auth Value / Token', _authValueCtrl),
            const Divider(color: Color(0xFF333333), height: 32),
            _buildDynamicList('Headers', _headers, () => setState(() => _headers.add(const MapEntry('', ''))), (i) => setState(() => _headers.removeAt(i))),
            const Divider(color: Color(0xFF333333), height: 32),
            _buildDynamicList('Query Params', _queryParams, () => setState(() => _queryParams.add(const MapEntry('', ''))), (i) => setState(() => _queryParams.removeAt(i))),
            const Divider(color: Color(0xFF333333), height: 32),
            const Text('Request Body Template', style: TextStyle(color: Color(0xFFFACC15), fontWeight: FontWeight.bold)),
            const Text('Use {code}, {stdin}, {language} as placeholders', style: TextStyle(color: Colors.grey, fontSize: 12)),
            _buildTextField('', _bodyTemplateCtrl, maxLines: 5),
            const Divider(color: Color(0xFF333333), height: 32),
            const Text('Response Mapping (Dot Notation)', style: TextStyle(color: Color(0xFFFACC15), fontWeight: FontWeight.bold)),
            _buildTextField('Stdout Path (e.g. data.output)', _stdoutCtrl),
            _buildTextField('Stderr Path', _stderrCtrl),
            _buildTextField('Error/Exception Path', _errorCtrl),
            _buildTextField('Execution Time Path', _timeCtrl),
            _buildTextField('Memory Path', _memoryCtrl),
          ],
        ),
      ),
    );
  }
}
