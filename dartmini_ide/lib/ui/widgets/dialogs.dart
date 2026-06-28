import 'package:flutter/material.dart';

Future<String?> showNewFileDialog(BuildContext context) async {
  String name = '';
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('New File'),
      content: TextField(
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'filename.dart',
          border: OutlineInputBorder(),
        ),
        onChanged: (val) => name = val,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (!name.endsWith('.dart')) name += '.dart';
            Navigator.pop(context, name);
          },
          child: const Text('Create'),
        ),
      ],
    ),
  );
}

Future<bool> showDeleteConfirmationDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete File?'),
      content: const Text('This cannot be undone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return result ?? false;
}
