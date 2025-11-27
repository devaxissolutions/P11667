import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF7C3AED);
  static const Color background = Color(0xFF0E0E10);
  static const Color surface = Color(0xFF151518);
  static const Color textPrimary = Color(0xFFEDEDED);
  static const Color textSecondary = Color(0xFF9CA3AF);
  static const Color divider = Color(0x15FFFFFF);
  static const Color icon = Color(0xFF9CA3AF);
  static const Color error = Color(0xFFCF6679); // Keeping error color for safety

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF9F67FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
