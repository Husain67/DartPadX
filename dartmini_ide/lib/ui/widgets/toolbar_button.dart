import 'package:flutter/material.dart';

class ToolbarButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const ToolbarButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
      child: Material(
        color: const Color(0xFFF3F4F6), // White/cream background as requested
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.0),
          side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.0),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(24.0),
          onTap: onPressed,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            alignment: Alignment.center,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
