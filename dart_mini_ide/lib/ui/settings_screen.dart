import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../providers/settings_provider.dart';
import '../models/compiler_preset.dart';
import '../services/compiler_service.dart';
import '../theme.dart';
import 'package:uuid/uuid.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _platformName;
  late String _endpointUrl;
  late String _httpMethod;
  late String _authType;
  late String _requestBodyTemplate;
  late String _stdoutPath;
  late String _stderrPath;
  late String _errorPath;
  late String _executionTimePath;
  late String _memoryPath;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Presets'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: AppTheme.gradientBackground,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildGlobalToggle(settings),
            const SizedBox(height: 24),
            const Text(
              'Compiler Presets',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primaryAccent),
            ),
            const SizedBox(height: 16),
            ...settings.presets.map((preset) => _buildPresetTile(preset, settings)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add New Preset'),
              onPressed: () => _showPresetDialog(null),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Import'),
                    onPressed: () => _importPresets(),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white24, foregroundColor: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.download),
                    label: const Text('Export'),
                    onPressed: () => _exportPresets(settings.presets),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white24, foregroundColor: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportPresets(List<CompilerPreset> presets) async {
    try {
      final jsonString = jsonEncode(presets.map((e) => e.toJson()).toList());
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/compiler_presets.json');
      await file.writeAsString(jsonString);
      await Share.shareXFiles([XFile(file.path)], subject: 'DartMini IDE Compiler Presets');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  Future<void> _importPresets() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      if (result != null) {
        File file = File(result.files.single.path!);
        String content = await file.readAsString();
        List<dynamic> jsonList = jsonDecode(content);
        for (var item in jsonList) {
          final preset = CompilerPreset.fromJson(item as Map<String, dynamic>);
          ref.read(settingsProvider.notifier).addPreset(preset);
        }
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Presets imported successfully')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Import failed: $e')));
    }
  }

  Widget _buildGlobalToggle(SettingsState settings) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundEnd,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Use Default OneCompiler', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('Toggle off to use selected custom API preset', style: TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: settings.useDefaultCompiler,
            activeColor: AppTheme.primaryAccent,
            onChanged: (val) {
              ref.read(settingsProvider.notifier).toggleCompilerMode(val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPresetTile(CompilerPreset preset, SettingsState settings) {
    final isSelected = settings.selectedPreset?.id == preset.id && !settings.useDefaultCompiler;

    return Card(
      color: isSelected ? AppTheme.primaryAccent.withOpacity(0.1) : AppTheme.backgroundEnd,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: isSelected ? AppTheme.primaryAccent : Colors.white12, width: isSelected ? 2 : 1),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(preset.platformName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(preset.endpointUrl, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.copy, color: Colors.white70),
              onPressed: () {
                final duplicate = preset.copyWith(
                  id: const Uuid().v4(),
                  platformName: '${preset.platformName} (Copy)',
                );
                ref.read(settingsProvider.notifier).addPreset(duplicate);
              },
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.white70),
              onPressed: () => _showPresetDialog(preset),
            ),
            if (preset.id != 'onecompiler') // Prevent deleting default
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: () {
                  ref.read(settingsProvider.notifier).removePreset(preset.id);
                },
              ),
          ],
        ),
        onTap: () {
          ref.read(settingsProvider.notifier).selectPreset(preset);
          ref.read(settingsProvider.notifier).toggleCompilerMode(false);
        },
      ),
    );
  }

  void _showPresetDialog(CompilerPreset? preset) {
    final isEdit = preset != null;
    _platformName = preset?.platformName ?? '';
    _endpointUrl = preset?.endpointUrl ?? '';
    _httpMethod = preset?.httpMethod ?? 'POST';
    _authType = preset?.authType ?? 'None';
    _requestBodyTemplate = preset?.requestBodyTemplate ?? '{"language": "dart", "code": "{code}"}';
    _stdoutPath = preset?.stdoutPath ?? 'stdout';
    _stderrPath = preset?.stderrPath ?? 'stderr';
    _errorPath = preset?.errorPath ?? 'error';
    _executionTimePath = preset?.executionTimePath ?? '';
    _memoryPath = preset?.memoryPath ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppTheme.backgroundStart,
          title: Text(isEdit ? 'Edit Preset' : 'New Preset', style: const TextStyle(color: AppTheme.primaryAccent)),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: _platformName,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Platform Name'),
                    onSaved: (val) => _platformName = val ?? '',
                    validator: (val) => val!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: _endpointUrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Endpoint URL'),
                    onSaved: (val) => _endpointUrl = val ?? '',
                    validator: (val) => val!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _httpMethod,
                    dropdownColor: AppTheme.backgroundEnd,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'HTTP Method'),
                    items: ['POST', 'GET', 'PUT'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (val) => setState(() => _httpMethod = val!),
                    onSaved: (val) => _httpMethod = val!,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _authType,
                    dropdownColor: AppTheme.backgroundEnd,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Auth Type'),
                    items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                    onChanged: (val) => setState(() => _authType = val!),
                    onSaved: (val) => _authType = val!,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: _requestBodyTemplate,
                    style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Request Body Template (JSON)', helperText: 'Use {code}, {stdin}, {language}'),
                    onSaved: (val) => _requestBodyTemplate = val ?? '',
                  ),
                  const SizedBox(height: 12),
                  const Text('Response Mapping (Dot Notation)', style: TextStyle(color: AppTheme.primaryAccent)),
                  const SizedBox(height: 8),
                  TextFormField(initialValue: _stdoutPath, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'stdout path'), onSaved: (val) => _stdoutPath = val ?? ''),
                  const SizedBox(height: 8),
                  TextFormField(initialValue: _stderrPath, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'stderr path'), onSaved: (val) => _stderrPath = val ?? ''),
                  const SizedBox(height: 8),
                  TextFormField(initialValue: _errorPath, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'error path'), onSaved: (val) => _errorPath = val ?? ''),
                  const SizedBox(height: 8),
                  TextFormField(initialValue: _executionTimePath, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'executionTime path'), onSaved: (val) => _executionTimePath = val ?? ''),
                  const SizedBox(height: 8),
                  TextFormField(initialValue: _memoryPath, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'memory path'), onSaved: (val) => _memoryPath = val ?? ''),
                  const SizedBox(height: 12),
                  const Text('Dynamic Request Data', style: TextStyle(color: AppTheme.primaryAccent)),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: jsonEncode(preset?.headers ?? {}),
                    style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Headers (JSON Format)'),
                    validator: (val) {
                      try {
                        if (val != null && val.isNotEmpty) jsonDecode(val);
                        return null;
                      } catch (e) {
                        return 'Invalid JSON';
                      }
                    },
                    onSaved: (val) {
                      if (val != null && val.isNotEmpty) {
                        try {
                           final map = jsonDecode(val) as Map<String, dynamic>;
                           preset?.headers.clear();
                           preset?.headers.addAll(map.map((k, v) => MapEntry(k, v.toString())));
                        } catch (e) {
                           // ignore formatting error
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: jsonEncode(preset?.queryParams ?? {}),
                    style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Query Params (JSON Format)'),
                    validator: (val) {
                      try {
                        if (val != null && val.isNotEmpty) jsonDecode(val);
                        return null;
                      } catch (e) {
                        return 'Invalid JSON';
                      }
                    },
                    onSaved: (val) {
                      if (val != null && val.isNotEmpty) {
                        try {
                           final map = jsonDecode(val) as Map<String, dynamic>;
                           preset?.queryParams.clear();
                           preset?.queryParams.addAll(map.map((k, v) => MapEntry(k, v.toString())));
                        } catch (e) {
                           // ignore formatting error
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  if (preset != null)
                     ElevatedButton.icon(
                       icon: const Icon(Icons.cable),
                       label: const Text('Test Connection'),
                       onPressed: () async {
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Testing connection...')));
                         // Save state temporarily for test
                         if (_formKey.currentState!.validate()) {
                            _formKey.currentState!.save();
                            final tempPreset = CompilerPreset(
                              id: preset.id,
                              platformName: _platformName,
                              endpointUrl: _endpointUrl,
                              httpMethod: _httpMethod,
                              authType: _authType,
                              headers: preset.headers,
                              queryParams: preset.queryParams,
                              requestBodyTemplate: _requestBodyTemplate,
                              stdoutPath: _stdoutPath,
                              stderrPath: _stderrPath,
                              errorPath: _errorPath,
                              executionTimePath: _executionTimePath,
                              memoryPath: _memoryPath,
                            );

                            final compilerService = CompilerService();
                            final result = await compilerService.executeCode("void main() { print('Hello from custom API'); }", tempPreset);

                            if (mounted) {
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: AppTheme.backgroundStart,
                                  title: const Text('Test Result', style: TextStyle(color: AppTheme.primaryAccent)),
                                  content: SingleChildScrollView(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Parsed Output:', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                                        Text(result.stdout, style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace')),
                                        if (result.stderr.isNotEmpty) ...[
                                          const SizedBox(height: 8),
                                          const Text('Error/Stderr:', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                                          Text(result.stderr, style: const TextStyle(color: Colors.redAccent, fontFamily: 'monospace')),
                                        ],
                                        const SizedBox(height: 8),
                                        const Text('Metrics:', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                                        Text('Time: ${result.time} | Memory: ${result.memory}', style: const TextStyle(color: Colors.yellowAccent, fontFamily: 'monospace')),
                                      ],
                                    ),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Close', style: TextStyle(color: Colors.white54)),
                                    ),
                                  ],
                                ),
                              );
                            }
                         }
                       },
                       style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey),
                     ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white54))),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  final newPreset = CompilerPreset(
                    id: preset?.id ?? const Uuid().v4(),
                    platformName: _platformName,
                    endpointUrl: _endpointUrl,
                    httpMethod: _httpMethod,
                    authType: _authType,
                    headers: preset?.headers ?? {},
                    queryParams: preset?.queryParams ?? {},
                    requestBodyTemplate: _requestBodyTemplate,
                    stdoutPath: _stdoutPath,
                    stderrPath: _stderrPath,
                    errorPath: _errorPath,
                    executionTimePath: _executionTimePath,
                    memoryPath: _memoryPath,
                  );
                  if (isEdit) {
                    ref.read(settingsProvider.notifier).updatePreset(newPreset);
                  } else {
                    ref.read(settingsProvider.notifier).addPreset(newPreset);
                  }
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
