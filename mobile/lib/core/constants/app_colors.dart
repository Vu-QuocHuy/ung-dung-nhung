import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors - Green Theme (giống React design)
  static const Color primary = Color(0xFF16A34A); // green-600
  static const Color primaryLight = Color(0xFF22C55E); // green-500
  static const Color primaryDark = Color(0xFF15803D); // green-700

  // Background
  static const Color background = Color(0xFFF9FAFB); // gray-50
  static const Color backgroundLight = Color(0xFFFFFFFF);
  static const Color backgroundDark = Color(0xFFF3F4F6); // gray-100

  // Text Colors
  static const Color textPrimary = Color(0xFF111827); // gray-900
  static const Color textSecondary = Color(0xFF6B7280); // gray-600
  static const Color textTertiary = Color(0xFF9CA3AF); // gray-400

  // Status Colors
  static const Color success = Color(0xFF10B981); // green-500
  static const Color warning = Color(0xFFF59E0B); // amber-500
  static const Color error = Color(0xFFEF4444); // red-500
  static const Color info = Color(0xFF3B82F6); // blue-500

  // Sensor Colors
  static const Color temperature = Color(0xFFF97316); // orange-500
  static const Color humidity = Color(0xFF3B82F6); // blue-500
  static const Color soilMoisture = Color(0xFF10B981); // green-500
  static const Color waterLevel = Color(0xFF06B6D4); // cyan-500
  static const Color light = Color(0xFFFBBF24); // amber-400

  // Border
  static const Color border = Color(0xFFE5E7EB); // gray-200
  static const Color divider = Color(0xFFE5E7EB);

  // Card & Surface
  static const Color card = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFFFFFFF);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF22C55E), Color(0xFF16A34A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
