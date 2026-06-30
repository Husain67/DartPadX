import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class IdeShortcuts extends ConsumerWidget {
  final Widget child;

  const IdeShortcuts({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CallbackShortcuts(
      bindings: {
        SingleActivator(LogicalKeyboardKey.keyS, control: true): () {
          // Saving is auto-handled, could add a toast or explicit save log here
        },
      },
      child: Focus(
        autofocus: true,
        child: child,
      ),
    );
  }
}
