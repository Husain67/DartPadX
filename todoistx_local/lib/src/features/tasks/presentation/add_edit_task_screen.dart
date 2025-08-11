import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:todoistx_local/src/common/models/project.dart';
import 'package:todoistx_local/src/common/models/tag.dart';
import 'package:todoistx_local/src/common/models/task.dart';
import 'package:todoistx_local/src/common/providers/data_providers.dart';
import 'package:uuid/uuid.dart';
import 'package:collection/collection.dart';

class AddEditTaskScreen extends ConsumerWidget {
  const AddEditTaskScreen({super.key, required this.taskId});
  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (taskId != 'new') {
      final asyncTask = ref.watch(taskProvider(taskId));
      return asyncTask.when(
        data: (task) => AddEditTaskForm(initialTask: task),
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
      );
    }
    return const AddEditTaskForm(initialTask: null);
  }
}

class AddEditTaskForm extends ConsumerStatefulWidget {
  const AddEditTaskForm({super.key, this.initialTask});
  final Task? initialTask;
  bool get isEditing => initialTask != null;

  @override
  ConsumerState<AddEditTaskForm> createState() => _AddEditTaskFormState();
}

class _AddEditTaskFormState extends ConsumerState<AddEditTaskForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  DateTime? _dueDateTime;
  int _priority = 0;
  String? _selectedProjectId;
  String? _imagePath;
  List<String> _selectedTagIds = [];
  List<DateTime> _reminderTimes = [];

  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;

  @override
  void initState() {
    super.initState();
    final task = widget.initialTask;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController = TextEditingController(text: task?.description ?? '');
    _dueDateTime = task?.dueDateTime;
    _priority = task?.priority ?? 0;
    _selectedProjectId = task?.projectId;
    _imagePath = task?.imagePath;
    _selectedTagIds = task?.tags ?? [];
    _reminderTimes = task?.reminderTimes ?? [];
    _initSpeech();
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize();
    if (mounted) setState(() {});
  }

  void _startListening(TextEditingController controller) async {
    await _speechToText.listen(onResult: (result) => setState(() => controller.text = result.recognizedWords));
    setState(() {});
  }

  void _stopListening() async {
    await _speechToText.stop();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveTask() async {
    if (_formKey.currentState!.validate()) {
      final taskRepository = ref.read(taskRepositoryProvider);
      final notificationService = ref.read(notificationServiceProvider);
      final now = DateTime.now();

      final taskToSave = Task(
        id: widget.isEditing ? widget.initialTask!.id : const Uuid().v4(),
        title: _titleController.text,
        description: _descriptionController.text,
        createdAt: widget.isEditing ? widget.initialTask!.createdAt : now,
        updatedAt: now,
        dueDateTime: _dueDateTime,
        isCompleted: widget.isEditing ? widget.initialTask!.isCompleted : false,
        priority: _priority,
        projectId: _selectedProjectId,
        imagePath: _imagePath,
        tags: _selectedTagIds,
        reminderTimes: _reminderTimes,
      );

      if (widget.isEditing) {
        await notificationService.cancelTaskReminders(widget.initialTask!);
      }
      await notificationService.scheduleTaskReminders(taskToSave);

      if (widget.isEditing) {
        await taskRepository.updateTask(taskToSave);
      } else {
        await taskRepository.addTask(taskToSave);
      }

      if (mounted) GoRouter.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final projects = ref.watch(projectsProvider);
    final allTags = ref.watch(tagsProvider);
    final selectedProject = projects.firstWhereOrNull((p) => p.id == _selectedProjectId);
    final selectedTags = allTags.where((t) => _selectedTagIds.contains(t.id)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Task' : 'Add Task'),
        actions: [IconButton(icon: const Icon(Icons.save), onPressed: _saveTask)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              if (_imagePath != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Stack(
                    children: [
                      Image.file(File(_imagePath!)),
                      Positioned(
                        top: 8, right: 8,
                        child: CircleAvatar(
                          backgroundColor: Colors.black54,
                          child: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => setState(() => _imagePath = null)),
                        ),
                      )
                    ],
                  ),
                ),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_speechToText.isListening ? Icons.mic_off : Icons.mic),
                    onPressed: _speechEnabled ? () => _speechToText.isNotListening ? _startListening(_titleController) : _stopListening() : null,
                  ),
                ),
                validator: (v) => (v == null || v.isEmpty) ? 'Please enter a title' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description (optional)',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_speechToText.isListening ? Icons.mic_off : Icons.mic),
                    onPressed: _speechEnabled ? () => _speechToText.isNotListening ? _startListening(_descriptionController) : _stopListening() : null,
                  ),
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _priority,
                decoration: const InputDecoration(labelText: 'Priority', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('Low')),
                  DropdownMenuItem(value: 1, child: Text('Medium')),
                  DropdownMenuItem(value: 2, child: Text('High')),
                ],
                onChanged: (value) => setState(() => _priority = value ?? 0),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: Text(_dueDateTime == null ? 'Select Due Date' : DateFormat.yMMMd().add_jm().format(_dueDateTime!)),
                onTap: () async {
                  final pDate = await showDatePicker(context: context, initialDate: _dueDateTime ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2101));
                  if (pDate != null && mounted) {
                    final pTime = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_dueDateTime ?? DateTime.now()));
                    if (pTime != null) setState(() => _dueDateTime = DateTime(pDate.year, pDate.month, pDate.day, pTime.hour, pTime.minute));
                  }
                },
                trailing: _dueDateTime != null ? IconButton(icon: const Icon(Icons.close), onPressed: () => setState(() => _dueDateTime = null)) : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedProject?.id,
                decoration: const InputDecoration(labelText: 'Project', border: OutlineInputBorder()),
                items: projects.map((p) => DropdownMenuItem<String>(value: p.id, child: Text(p.name))).toList(),
                onChanged: (value) => setState(() => _selectedProjectId = value),
              ),
              const Divider(height: 32),
              Wrap(
                spacing: 8.0,
                children: [
                  ...selectedTags.map((tag) => Chip(label: Text(tag.name), onDeleted: () => setState(() => _selectedTagIds.remove(tag.id)))),
                  ActionChip(avatar: const Icon(Icons.add), label: const Text('Add Tag'), onPressed: () => _showTagDialog(context, allTags)),
                ],
              ),
              const Divider(height: 32),
              OutlinedButton.icon(
                icon: const Icon(Icons.attach_file),
                label: const Text('Attach Image'),
                onPressed: () async {
                  final imageService = ref.read(imageServiceProvider);
                  final newImagePath = await imageService.pickAndSaveImage();
                  if (newImagePath != null) setState(() => _imagePath = newImagePath);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTagDialog(BuildContext context, List<Tag> allTags) {
    showDialog(
      context: context,
      builder: (context) {
        final newTagController = TextEditingController();
        return AlertDialog(
          title: const Text('Select or Create Tag'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: newTagController,
                  decoration: const InputDecoration(hintText: 'Create new tag'),
                  onSubmitted: (name) {
                    if (name.isNotEmpty) {
                      _addNewTag(name);
                      Navigator.of(context).pop();
                    }
                  },
                ),
                const Divider(),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: allTags.map((tag) {
                      final isSelected = _selectedTagIds.contains(tag.id);
                      return CheckboxListTile(
                        title: Text(tag.name),
                        value: isSelected,
                        onChanged: (bool? selected) {
                          setState(() {
                            if (selected == true) {
                              _selectedTagIds.add(tag.id);
                            } else {
                              _selectedTagIds.remove(tag.id);
                            }
                          });
                          Navigator.of(context).pop();
                          _showTagDialog(context, allTags);
                        },
                      );
                    }).toList(),
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

  void _addNewTag(String name) {
    final tagRepository = ref.read(tagRepositoryProvider);
    final newTag = Tag(id: const Uuid().v4(), name: name.trim());
    tagRepository.addTag(newTag);
    setState(() {
      _selectedTagIds.add(newTag.id);
    });
  }
}
