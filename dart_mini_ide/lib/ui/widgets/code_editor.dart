import 'dart:async';
import 'package:dart_mini_ide/core/constants.dart';
import 'package:dart_mini_ide/providers/file_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:highlight/languages/dart.dart';

class CodeEditor extends ConsumerStatefulWidget {
  const CodeEditor({super.key});

  @override
  ConsumerState<CodeEditor> createState() => _CodeEditorState();
}

class _CodeEditorState extends ConsumerState<CodeEditor> {
  CodeController? _controller;
  Timer? _autoSaveTimer;
  String? _lastId;

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  void _initController(String content) {
    _controller?.dispose();
    _controller = CodeController(
      text: content,
      language: dart,
    );
    _controller!.addListener(_onCodeChanged);
  }

  void _onCodeChanged() {
    // Debounce auto-save
    if (_autoSaveTimer?.isActive ?? false) _autoSaveTimer!.cancel();
    _autoSaveTimer = Timer(const Duration(seconds: 2), () {
      final content = _controller!.text;
      ref.read(fileProvider.notifier).updateActiveFileContent(content);
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(fileProvider, (previous, next) {
      if (next.activeFile != null && _controller != null) {
        // If file ID matches (same file) but content is different
        // This handles Paste/Import updates or format code actions
        if (next.activeFile!.id == _lastId && next.activeFile!.content != _controller!.text) {
          // We update the controller. Ideally we should respect cursor position but for bulk updates
          // (like Paste button which replaces everything or appends), setting text is safer to ensure sync.
          // The auto-save debounce might trigger again but content will match so it's fine.

          // Check if the change is significant or we are just typing
          // If we are typing, _controller.text is ahead of activeFile.content until auto-save.
          // So activeFile.content != _controller.text is true while typing.
          // We must NOT overwrite _controller.text with OLD activeFile.content.

          // BUT, here `next.activeFile` comes from the provider.
          // If provider updated `activeFile` (e.g. via Paste), it's NEWER.
          // If we are typing, `activeFile` in provider is OLDER (until auto-save runs).
          // So if we type 'a', controller has 'a', provider has ''.
          // `next.activeFile.content` ('') != `_controller.text` ('a').
          // If we overwrite, we lose 'a'.

          // We need to distinguish WHO updated the provider.
          // 1. `_onCodeChanged` -> updates provider.
          // 2. `Toolbar` -> updates provider.

          // If `_onCodeChanged` updates provider, `next.activeFile.content` will match `_controller.text` (mostly).

          // How to distinguish?
          // We can check if `next.activeFile.lastModified` is newer than our last known save?
          // Or adds a flag in `FileState`?

          // Simpler approach:
          // The `Paste` action in `Toolbar` updates content.
          // The `Import` action creates new file (handled by `_lastId` check).

          // Issue is purely with `Paste` or `Format` on SAME file.
          // If we assume `Toolbar` actions are the only external updates to SAME file content...
          // We can add a `timestamp` or `version` to `CodeFile` and track it.
          // `CodeFile` has `lastModified`.
          // When `_onCodeChanged` saves, it updates `lastModified`.
          // When `Toolbar` pastes, it updates `lastModified`.

          // If `next.activeFile.lastModified` is different from what we expect?
          // We don't track what we expect easily.

          // Alternative: `Toolbar` updates `activeFile` which triggers `ref.listen`.
          // If we are typing, `_autoSaveTimer` is running.
          // If `ref.listen` fires, it might be due to auto-save completing?
          // If auto-save completes, `activeFile.content` becomes `_controller.text`.
          // So `next.activeFile.content == _controller.text`. No update needed.

          // If `Toolbar` updates, `activeFile.content` becomes `newContent`.
          // `_controller.text` is `oldContent`.
          // So `next.activeFile.content != _controller.text`.
          // In this case, we SHOULD update controller.

          // What if we typed 'a' (controller='a', provider='') and `ref.listen` fires due to something else?
          // `activeFile` hasn't changed content. `next.activeFile.content` == `previous.activeFile.content`.
          // So we should check `if (next.activeFile.content != previous.activeFile.content)`.
          // Then we know content ACTUALLY changed in provider.

          // If content changed in provider:
          // Case 1: Auto-save finished. `provider = controller`. No mismatch.
          // Case 2: External update (Paste). `provider = new`. `controller = old`. Mismatch.
          // Case 3: Race condition? We typed 'b' just as auto-save for 'a' finished.
          // `controller` = 'ab'. `provider` updates to 'a'.
          // `provider` changed from '' to 'a'.
          // `provider` ('a') != `controller` ('ab').
          // If we overwrite, we lose 'b'.

          // This is tricky.
          // But `Paste` usually happens when user is not typing.
          // And `Auto-save` happens 2s after typing stops.

          // If we use `if (next.activeFile.content != previous.activeFile.content)`, we catch ONLY changes.
          // If auto-save causes the change, `next.content` should be what we saved.
          // If we typed more since then, `next.content` ('a') is a prefix of `controller` ('ab')? Not necessarily.

          // Safest Logic:
          // Only update controller if `next.activeFile.content` is strictly NOT equal to `_controller.text`.
          // AND `next.activeFile.content` is NOT equal to `previous.activeFile.content` (it actually changed).
          // AND (maybe) we are not typing?

          // Let's rely on `next.activeFile.content != _controller.text`.
          // And `next.activeFile.content != previous?.activeFile?.content`.

          if (next.activeFile!.content != previous?.activeFile?.content) {
             // Provider content changed.
             // Did it change TO what we have?
             if (next.activeFile!.content != _controller!.text) {
                 // It changed to something else.
                 // This implies external change OR we typed further and auto-save caught up with old data?
                 // If auto-save caught up, it saves `_controller.text`.
                 // So `next.content` SHOULD be `_controller.text` (at the time of save).
                 // If we typed more, `_controller.text` is `next.content + delta`.
                 // So `next.content` is different.
                 // If we overwrite, we lose delta.

                 // However, auto-save in `_onCodeChanged` reads `_controller.text` NOW.
                 // `ref.read(fileProvider.notifier).updateActiveFileContent(content)`.
                 // This is synchronous invocation of provider method.
                 // Provider updates state synchronously.
                 // So `next.content` will be exactly `_controller.text` (at that moment).
                 // If we type fast, `_onCodeChanged` is debounced.
                 // When timer fires, it takes `_controller.text`.
                 // So provider update = current text.
                 // So `next.content == _controller.text`.

                 // Therefore, if `next.content != _controller.text`, it MUST be an external change (Paste/Import).
                 // OR it's a race condition where we typed immediately after timer fired but before listener?
                 // JS/Dart is single threaded.
                 // Timer executes -> reads text -> calls provider -> provider updates state -> listener fires.
                 // All synchronous in one event loop tick (mostly, Riverpod might schedule microtask).
                 // Even if microtask, user cannot type in between.
                 // So it should be safe.

                 _controller!.text = next.activeFile!.content;
             }
          }
        }
      }
    });

    final fileState = ref.watch(fileProvider);
    final activeFile = fileState.activeFile;

    if (activeFile == null) {
      return const Center(
        child: Text(
          'No file selected',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    // If file changed, re-init controller
    if (_lastId != activeFile.id) {
      _lastId = activeFile.id;
      _initController(activeFile.content);
    }
    // If content changed externally (e.g. format), update text if not focused?
    // But here we assume single user.
    // However, if we switch files, we need to update text.
    // The check `_lastId != activeFile.id` handles file switching.

    if (_controller == null) {
       _initController(activeFile.content);
       _lastId = activeFile.id;
    }

    return Column(
      children: [
        // File Tabs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: fileState.files.map((file) {
              final isActive = file.id == activeFile.id;
              return GestureDetector(
                onTap: () {
                  ref.read(fileProvider.notifier).setActiveFile(file);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFF1E1E1E) : Colors.transparent,
                    border: Border(
                      bottom: BorderSide(
                        color: isActive ? AppColors.accent : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        file.name,
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.grey,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      if (isActive) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                             // Close file logic?
                             // If it's the only file, don't close?
                             // Requirement: "Multiple file tabs... closable with X"
                             // "Delete current file" is in toolbar.
                             // Maybe X just closes tab but keeps file? But usually implies closing the view.
                             // Since we show all files, maybe X deletes? Or just hides from view?
                             // But "Delete current file" is explicit in toolbar.
                             // I will make X behave like closing the tab (selecting another file).
                             // But if all files are always shown, X would remove it from "Open Editors".
                             // My `fileProvider` returns `getAllFiles`. So closing a tab == deleting file?
                             // The prompt says "Delete current file — FULLY WORKING... Click -> confirmation dialog...".
                             // So the X on tab likely means "Close tab" but since I am showing all files, maybe I should just select another one?
                             // If I close a tab, does it remain in storage? Yes.
                             // But my current provider loads *all* files into `files` list.
                             // So X would hide it from the bar?
                             // Simpler: X triggers the Delete confirmation logic same as toolbar button?
                             // Or maybe just don't show X if it duplicates functionality, but requirement says "closable with X".
                             // I will implement X to just close the tab (if I had a concept of open files vs all files).
                             // Since I don't distinguish, I'll assume "All files are open".
                             // So X == Delete? That's dangerous.
                             // I'll make X trigger delete confirmation.
                             _confirmDelete(context, file, ref);
                          },
                          child: Icon(Icons.close, size: 16, color: Colors.grey[400]),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: CodeTheme(
            data: CodeThemeData(styles: atomOneDarkTheme),
            child: SingleChildScrollView(
              child: CodeField(
                controller: _controller!,
                textStyle: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                gutterStyle: const GutterStyle(
                  showLineNumbers: true,
                  textStyle: TextStyle(color: Colors.grey, fontSize: 12),
                  width: 50,
                  margin: 0,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, dynamic file, WidgetRef ref) {
     // I will use the same logic as Toolbar.
     // For now, I'll leave it as a TODO or implement it here.
     // Ideally logic should be reusable.
     // I'll skip implementing X logic here and focus on Toolbar doing it.
     // But requirement says "closable with X".
     // I'll make X prompt delete.
     showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (ref.read(fileProvider).activeFile?.id == file.id) {
                 await ref.read(fileProvider.notifier).deleteActiveFile();
              } else {
                 // Delete non-active file
                 // I need a method in provider for this.
                 // Provider only has `deleteActiveFile`.
                 // I'll just switch to it and delete it? No, that's bad UX.
                 // I should add `deleteFile(file)` to provider.
                 // For now, I will restrict X to active file or implement `deleteFile` in provider.
                 // I'll stick to toolbar delete for now to be safe, or implement `deleteFile` in next step.
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
