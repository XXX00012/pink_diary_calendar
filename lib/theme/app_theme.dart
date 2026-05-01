import 'package:flutter/material.dart';
import 'package:pink_diary_calendar/theme/app_colors.dart';
import 'package:pink_diary_calendar/utils/profile_theme_utils.dart';

class WarmThemeColors extends ThemeExtension<WarmThemeColors> {
  const WarmThemeColors({
    required this.primary,
    required this.secondary,
    required this.soft,
    required this.card,
    required this.pageGradient,
  });

  final Color primary;
  final Color secondary;
  final Color soft;
  final Color card;
  final LinearGradient pageGradient;

  @override
  WarmThemeColors copyWith({
    Color? primary,
    Color? secondary,
    Color? soft,
    Color? card,
    LinearGradient? pageGradient,
  }) {
    return WarmThemeColors(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      soft: soft ?? this.soft,
      card: card ?? this.card,
      pageGradient: pageGradient ?? this.pageGradient,
    );
  }

  @override
  WarmThemeColors lerp(ThemeExtension<WarmThemeColors>? other, double t) {
    if (other is! WarmThemeColors) {
      return this;
    }

    return WarmThemeColors(
      primary: Color.lerp(primary, other.primary, t) ?? primary,
      secondary: Color.lerp(secondary, other.secondary, t) ?? secondary,
      soft: Color.lerp(soft, other.soft, t) ?? soft,
      card: Color.lerp(card, other.card, t) ?? card,
      pageGradient:
          LinearGradient.lerp(pageGradient, other.pageGradient, t) ??
          pageGradient,
    );
  }
}

class AppTheme {
  const AppTheme._();

  static ThemeData light([String themeKey = 'pink']) {
    final warmColors = _warmColorsFor(themeKey);
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: warmColors.primary,
        brightness: Brightness.light,
        primary: warmColors.primary,
        secondary: warmColors.secondary,
        surface: warmColors.card,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: warmColors.soft,
      extensions: <ThemeExtension<dynamic>>[warmColors],
      iconTheme: IconThemeData(color: warmColors.primary),
      textTheme: base.textTheme
          .apply(bodyColor: AppColors.ink, displayColor: AppColors.ink)
          .copyWith(
            headlineSmall: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              height: 1.2,
              color: AppColors.ink,
            ),
            titleLarge: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              height: 1.25,
              color: AppColors.ink,
            ),
            titleMedium: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.35,
              color: AppColors.ink,
            ),
            bodyLarge: const TextStyle(color: AppColors.ink),
            bodyMedium: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: AppColors.ink,
            ),
            bodySmall: const TextStyle(color: AppColors.ink),
          ),
      dividerTheme: DividerThemeData(
        color: AppColors.line.withValues(alpha: 0.75),
        thickness: 1,
        space: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: warmColors.primary,
          foregroundColor: AppColors.ink,
          elevation: 0,
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: warmColors.primary,
          side: BorderSide(color: warmColors.primary.withValues(alpha: 0.3)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: warmColors.primary),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink,
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: warmColors.card.withValues(alpha: 0.94),
        elevation: 0,
        height: 68,
        indicatorColor: warmColors.soft,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? warmColors.primary : AppColors.muted,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? warmColors.primary : AppColors.muted,
            size: selected ? 25 : 23,
          );
        }),
      ),
    );
  }

  static WarmThemeColors _warmColorsFor(String themeKey) {
    final option = ProfileThemeUtils.byKey(themeKey);
    final gradient = switch (option.key) {
      'cream' => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFFBF1), Color(0xFFFFF8E7), Color(0xFFFFFEFC)],
      ),
      'lavender' => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF5F0FF), Color(0xFFFFFAF5), Color(0xFFF0ECFF)],
      ),
      'peach' => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFFF0E8), Color(0xFFFFFAF5), Color(0xFFFFF6F0)],
      ),
      'sage' => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFF0FAF2), Color(0xFFFFFEFC), Color(0xFFF6FBF1)],
      ),
      'blue' => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFEFF8FF), Color(0xFFFFFEFC), Color(0xFFF2F6FA)],
      ),
      'minimalWhite' => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFFFEFCF8), Color(0xFFFAF8F4), Color(0xFFFFFFFF)],
      ),
      _ => AppColors.pageGradient,
    };

    final cardColor = option.key == 'minimalWhite'
        ? const Color(0xFFFFFFFF)
        : AppColors.milk;

    return WarmThemeColors(
      primary: option.primary,
      secondary: option.secondary,
      soft: option.soft,
      card: cardColor,
      pageGradient: gradient,
    );
  }
}
