import 'package:flutter/material.dart';
import 'package:dart_mini_ide/core/constants/app_colors.dart';

class PillButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool isDestructive;

  const PillButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.toolbarButtonBg,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.toolbarButtonBorder,
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: isDestructive ? Colors.red : Colors.black87,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}
