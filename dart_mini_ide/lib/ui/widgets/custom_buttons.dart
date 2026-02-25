import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ToolbarButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final Color? color;
  final Color? backgroundColor;

  const ToolbarButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(50),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: backgroundColor ?? AppTheme.toolbarButtonBg,
              borderRadius: BorderRadius.circular(50),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: color ?? Colors.black87,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

class PillButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final VoidCallback onPressed;
  final bool isPrimary;

  const PillButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isPrimary = true,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? AppTheme.primaryAccent : AppTheme.surfaceColor,
        foregroundColor: isPrimary ? Colors.black : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
          side: isPrimary ? BorderSide.none : BorderSide(color: Colors.white.withOpacity(0.2)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18),
            const SizedBox(width: 8),
          ],
          Text(text),
        ],
      ),
    );
  }
}
