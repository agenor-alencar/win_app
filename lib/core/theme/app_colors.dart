import 'package:flutter/material.dart';

/// Tokens de cor da marca WIN. Fonte única — não use literais de cor espalhados.
class AppColors {
  AppColors._();

  static const Color brand = Color(0xFF007AFF);
  static const Color brandDark = Color(0xFF0A84FF);

  static const Color danger = Color(0xFFE53935);
  static const Color success = Color(0xFF2E7D32);

  // Superfícies (claro)
  static const Color scaffoldLight = Color(0xFFFBFBFB);
  static const Color surfaceLight = Colors.white;

  // Superfícies (escuro)
  static const Color scaffoldDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
}
