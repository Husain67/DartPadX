import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class KeyboardShortcutsHandler extends StatelessWidget {
  final Widget child;
  final VoidCallback onSave;
  final VoidCallback onRun;
  final VoidCallback onFormat;

  const KeyboardShortcutsHandler({
    super.key,
    required this.child,
    required this.onSave,
    required this.onRun,
    required this.onFormat,
  });

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): onSave,
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true): onSave,
        const SingleActivator(LogicalKeyboardKey.enter, control: true): onRun,
        const SingleActivator(LogicalKeyboardKey.enter, meta: true): onRun,
        const SingleActivator(LogicalKeyboardKey.keyF, control: true, shift: true): onFormat,
        const SingleActivator(LogicalKeyboardKey.keyF, meta: true, shift: true): onFormat,
      },
      child: Focus(
        autofocus: true,
        child: child,
      ),
    );
  }
}
