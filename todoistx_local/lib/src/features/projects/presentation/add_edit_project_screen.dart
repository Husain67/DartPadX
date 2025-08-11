import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:todoistx_local/src/common/models/project.dart';
import 'package:todoistx_local/src/common/providers/data_providers.dart';
import 'package:uuid/uuid.dart';

class AddEditProjectScreen extends ConsumerWidget {
  const AddEditProjectScreen({super.key, required this.projectId});
  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (projectId != 'new') {
      final asyncProject = ref.watch(projectProvider(projectId));
      return asyncProject.when(
        data: (project) => AddEditProjectForm(initialProject: project),
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
      );
    }
    return const AddEditProjectForm(initialProject: null);
  }
}

class AddEditProjectForm extends ConsumerStatefulWidget {
  const AddEditProjectForm({super.key, this.initialProject});
  final Project? initialProject;
  bool get isEditing => initialProject != null;

  @override
  ConsumerState<AddEditProjectForm> createState() => _AddEditProjectFormState();
}

class _AddEditProjectFormState extends ConsumerState<AddEditProjectForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  Color _selectedColor = Colors.blue;
  IconData _selectedIcon = Icons.work;

  final List<IconData> _icons = [
    Icons.work, Icons.home, Icons.person, Icons.school, Icons.shopping_cart,
    Icons.favorite, Icons.book, Icons.lightbulb, Icons.flag, Icons.star,
  ];

  @override
  void initState() {
    super.initState();
    final project = widget.initialProject;
    _nameController = TextEditingController(text: project?.name ?? '');
    _selectedColor = project != null ? Color(project.color) : Colors.blue;
    if (project != null) {
      _selectedIcon = _icons.firstWhere(
        (icon) => icon.codePoint.toString() == project.icon,
        orElse: () => Icons.work,
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveProject() async {
    if (_formKey.currentState!.validate()) {
      final projectRepository = ref.read(projectRepositoryProvider);

      final projectToSave = Project(
        id: widget.isEditing ? widget.initialProject!.id : const Uuid().v4(),
        name: _nameController.text,
        color: _selectedColor.value,
        icon: _selectedIcon.codePoint.toString(),
      );

      if (widget.isEditing) {
        await projectRepository.updateProject(projectToSave);
      } else {
        await projectRepository.addProject(projectToSave);
      }

      if (mounted) {
        GoRouter.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Project' : 'Add Project'),
        actions: [IconButton(icon: const Icon(Icons.save), onPressed: _saveProject)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Project Name', border: OutlineInputBorder()),
                validator: (v) => (v == null || v.isEmpty) ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 24),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(backgroundColor: _selectedColor, child: Icon(_selectedIcon, color: Colors.white)),
                title: const Text('Project Color & Icon'),
                onTap: () => _showAppearanceDialog(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAppearanceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Choose Appearance'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Color'),
                ColorPicker(
                  pickerColor: _selectedColor,
                  onColorChanged: (color) => setState(() => _selectedColor = color),
                  pickerAreaHeightPercent: 0.8,
                ),
                const SizedBox(height: 20),
                const Text('Icon'),
                SizedBox(
                  height: 200,
                  width: 300,
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5),
                    itemCount: _icons.length,
                    itemBuilder: (context, index) {
                      final icon = _icons[index];
                      return IconButton(
                        icon: Icon(icon),
                        color: _selectedIcon == icon ? _selectedColor : Colors.grey,
                        onPressed: () => setState(() => _selectedIcon = icon),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [TextButton(child: const Text('Done'), onPressed: () => Navigator.of(context).pop())],
        );
      },
    );
  }
}
