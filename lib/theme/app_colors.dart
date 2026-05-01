import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const Color cream = Color(0xFFFFFAF5);
  static const Color milk = Color(0xFFFFFEFC);
  static const Color blush = Color(0xFFFFEEF2);
  static const Color peach = Color(0xFFF7C8B8);
  static const Color rose = Color(0xFFE7A6B6);
  static const Color roseDeep = Color(0xFFC96F87);
  static const Color lavender = Color(0xFFD8C9EE);
  static const Color lavenderDeep = Color(0xFF9B83C9);
  static const Color butter = Color(0xFFF5E3AA);
  static const Color sage = Color(0xFFBFD5C2);
  static const Color ink = Color(0xFF594B4F);
  static const Color muted = Color(0xFF9C858C);
  static const Color line = Color(0xFFF1D9DF);

  static const LinearGradient pageGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFEEF2), Color(0xFFFFFAF5), Color(0xFFF8F1FF)],
  );
}
