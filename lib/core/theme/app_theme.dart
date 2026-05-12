import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const Color primary = Color(0xFF16A34A);
  static const Color accent = Color(0xFF06B6D4);
  static const Color gold = Color(0xFFF59E0B);

  static const Color lightBg = Color(0xFFF7FAF8);
  static const Color lightText = Color(0xFF172033);
  static const Color lightSubText = Color(0xFF667085);

  static const Color darkBg = Color(0xFF0F172A);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkText = Color(0xFFF8FAFC);
  static const Color darkSubText = Color(0xFFCBD5E1);

  static const LinearGradient gradient = LinearGradient(
    colors: [Color(0xFF16A34A), Color(0xFF06B6D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppAssets {
  const AppAssets._();

  static const String logo = 'assets/logo.png';
}
