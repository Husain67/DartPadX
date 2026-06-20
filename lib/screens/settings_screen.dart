
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/compiler_preset.dart';
import '../providers/compiler_provider.dart';
import '../theme/app_theme.dart';

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
        backgroundColor: AppTheme.backgroundBlack,
        appBar: AppBar(
          title: const Text('Settings'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'General'),
              Tab(text: 'Compiler Presets'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _GeneralSettings(),
            _CompilerSettings(),
          ],
        ),
      ),
    );
  }
}

class _GeneralSettings extends StatelessWidget {
  const _GeneralSettings();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          title: const Text('Theme'),
          subtitle: const Text('VIDTSX Dark Theme (Locked)'),
          leading: const Icon(Icons.dark_mode, color: AppTheme.primaryAccent),
          onTap: () {},
        ),
        const Divider(),
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('About DartMini IDE', style: TextStyle(color: AppTheme.primaryAccent, fontWeight: FontWeight.bold)),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Version: Beta 1.0.0\n'
            'A purely mobile-first, high-performance Dart coding environment.',
            style: TextStyle(color: AppTheme.textMuted),
          ),
        ),
      ],
    );
  }
}

class _CompilerSettings extends ConsumerStatefulWidget {
  const _CompilerSettings();

  @override
  ConsumerState<_CompilerSettings> createState() => _CompilerSettingsState();
}

class _CompilerSettingsState extends ConsumerState<_CompilerSettings> {
  CompilerPreset? _selectedPreset;

  @override
  Widget build(BuildContext context) {
    final compilerState = ref.watch(compilerProvider);

    // Auto-select current default if none selected in UI
    if (_selectedPreset == null && compilerState.presets.isNotEmpty) {
      try {
        _selectedPreset = compilerState.presets.firstWhere((p) => p.id == compilerState.currentPresetId);
      } catch (_) {
        _selectedPreset = compilerState.presets.first;
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          children: [
            Container(
              height: 60,
              color: AppTheme.surfaceBlack,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: compilerState.presets.length + 1,
                itemBuilder: (context, index) {
                  if (index == compilerState.presets.length) {
                    return IconButton(
                      icon: const Icon(Icons.add_circle, color: AppTheme.primaryAccent),
                      onPressed: () {
                        _createNewPreset();
                      },
                    );
                  }

                  final preset = compilerState.presets[index];
                  final isSelected = _selectedPreset?.id == preset.id;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedPreset = preset;
                      });
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryAccent : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.primaryAccent),
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        children: [
                          Text(
                            preset.name,
                            style: TextStyle(
                              color: isSelected ? AppTheme.appbarBlack : AppTheme.primaryAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (preset.id == compilerState.currentPresetId)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Icon(Icons.check_circle, size: 14, color: isSelected ? AppTheme.appbarBlack : AppTheme.primaryAccent),
                            )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: _selectedPreset == null
                  ? const Center(child: Text('No preset selected'))
                  : _PresetEditor(
                      preset: _selectedPreset!,
                      onChanged: (updated) {
                        setState(() {
                          _selectedPreset = updated;
                        });
                        ref.read(compilerProvider.notifier).updatePreset(updated);
                      },
                    ),
            ),
          ],
        );
      }
    );
  }

  void _createNewPreset() {
    final newPreset = CompilerPreset(
      id: const Uuid().v4(),
      name: 'New Custom API',
      endpointUrl: '',
      httpMethod: 'POST',
      authType: 'None',
      headers: {'Content-Type': 'application/json'},
      queryParams: {},
      requestBodyTemplate: '{}',
      stdoutPath: '',
      stderrPath: '',
      errorPath: '',
      executionTimePath: '',
      memoryPath: '',
    );
    ref.read(compilerProvider.notifier).addPreset(newPreset);
    setState(() {
      _selectedPreset = newPreset;
    });
  }
}

class _PresetEditor extends ConsumerWidget {
  final CompilerPreset preset;
  final ValueChanged<CompilerPreset> onChanged;

  const _PresetEditor({required this.preset, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCurrentDefault = ref.watch(compilerProvider).currentPresetId == preset.id;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            ElevatedButton.icon(
              onPressed: isCurrentDefault
                ? null
                : () {
                    ref.read(compilerProvider.notifier).switchPreset(preset.id);
                  },
              icon: Icon(isCurrentDefault ? Icons.check : Icons.star_border),
              label: Text(isCurrentDefault ? 'Active Default' : 'Set as Default'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isCurrentDefault ? Colors.green : AppTheme.buttonCream,
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.copy, color: Colors.blue),
                  onPressed: () {
                    final clone = CompilerPreset(
                      id: const Uuid().v4(),
                      name: '${preset.name} Copy',
                      endpointUrl: preset.endpointUrl,
                      httpMethod: preset.httpMethod,
                      authType: preset.authType,
                      headers: Map.from(preset.headers),
                      queryParams: Map.from(preset.queryParams),
                      requestBodyTemplate: preset.requestBodyTemplate,
                      stdoutPath: preset.stdoutPath,
                      stderrPath: preset.stderrPath,
                      errorPath: preset.errorPath,
                      executionTimePath: preset.executionTimePath,
                      memoryPath: preset.memoryPath,
                      isDefault: false,
                    );
                    ref.read(compilerProvider.notifier).addPreset(clone);
                  },
                  tooltip: 'Duplicate',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    ref.read(compilerProvider.notifier).deletePreset(preset.id);
                  },
                  tooltip: 'Delete',
                ),
              ],
            )
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField('Platform Name', preset.name, (val) => onChanged(preset.copyWith(name: val))),
        _buildTextField('Endpoint URL', preset.endpointUrl, (val) => onChanged(preset.copyWith(endpointUrl: val)), maxLines: 2),

        DropdownButtonFormField<String>(
          // ignore: deprecated_member_use
          value: preset.httpMethod,
          decoration: const InputDecoration(labelText: 'HTTP Method'),
          dropdownColor: AppTheme.surfaceBlack,
          items: ['GET', 'POST', 'PUT'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
          onChanged: (val) {
            if (val != null) onChanged(preset.copyWith(httpMethod: val));
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          // ignore: deprecated_member_use
          value: preset.authType,
          decoration: const InputDecoration(labelText: 'Auth Type'),
          dropdownColor: AppTheme.surfaceBlack,
          items: ['None', 'API-Key Header', 'Bearer Token', 'Basic Auth', 'Query Param'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
          onChanged: (val) {
            if (val != null) onChanged(preset.copyWith(authType: val));
          },
        ),
        const SizedBox(height: 16),
        const Text('Request Body Template', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryAccent)),
        const Text('Use {code}, {stdin}, {language}', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
        _buildTextField('', preset.requestBodyTemplate, (val) => onChanged(preset.copyWith(requestBodyTemplate: val)), maxLines: 6),

        const SizedBox(height: 16),
        const Text('Response Mapping (Dot Notation)', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryAccent)),
        _buildTextField('Stdout Path', preset.stdoutPath, (val) => onChanged(preset.copyWith(stdoutPath: val))),
        _buildTextField('Stderr Path', preset.stderrPath, (val) => onChanged(preset.copyWith(stderrPath: val))),
        _buildTextField('Error Path', preset.errorPath, (val) => onChanged(preset.copyWith(errorPath: val))),
        _buildTextField('Execution Time Path', preset.executionTimePath, (val) => onChanged(preset.copyWith(executionTimePath: val))),
        _buildTextField('Memory Path', preset.memoryPath, (val) => onChanged(preset.copyWith(memoryPath: val))),

        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () async {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Testing connection...')),
            );
          },
          child: const Text('Test Connection'),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildTextField(String label, String value, ValueChanged<String> onChanged, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        initialValue: value,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label.isNotEmpty ? label : null,
          filled: true,
          fillColor: AppTheme.surfaceBlack,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
