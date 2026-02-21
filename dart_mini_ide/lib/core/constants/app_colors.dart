import 'package:flutter/material.dart';

class AppColors {
  static const Color backgroundStart = Color(0xFF050505);
  static const Color backgroundEnd = Color(0xFF1A1A1A);
  static const Color accent = Color(0xFFFACC15);
  static const Color toolbarButtonBg = Color(0xFFF5F5F5); // White/Cream
  static const Color toolbarButtonBorder = Color(0xFFE0E0E0);
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0B0);

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundStart, backgroundEnd],
  );
}
