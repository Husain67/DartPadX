import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/constants.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onRunPressed;
  final bool isExecuting;

  const CustomAppBar({
    Key? key,
    required this.onRunPressed,
    this.isExecuting = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            AppConstants.appName,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primaryAccent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              AppConstants.betaBadge,
              style: TextStyle(
                color: Colors.black,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0, top: 8.0, bottom: 8.0),
          child: ElevatedButton.icon(
            onPressed: isExecuting ? null : onRunPressed,
            icon: isExecuting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  )
                : const Icon(Icons.play_arrow, color: Colors.black),
            label: Text(isExecuting ? 'Running...' : 'Run'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryAccent,
              disabledBackgroundColor: AppTheme.primaryAccent.withValues(alpha: 0.5),
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(56.0);
}
