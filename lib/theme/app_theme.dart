import 'package:flutter/material.dart';
import 'package:pink_diary_calendar/theme/app_colors.dart';
import 'package:pink_diary_calendar/utils/profile_theme_utils.dart';

class WarmThemeColors extends ThemeExtension<WarmThemeColors> {
  const WarmThemeColors({
    required this.primary,
    required this.primarySoft,
    required this.secondary,
    required this.accent,
    required this.soft,
    required this.card,
    required this.textPrimary,
    required this.textSecondary,
    required this.calendarCardBackground,
    required this.planCardBackground,
    required this.expenseCardBackground,
    required this.lifeListCardBackground,
    required this.profileIconBackground,
    required this.sectionTitleColor,
    required this.bottomNavSelected,
    required this.bottomNavUnselected,
    required this.illustrationColor,
    required this.pageGradient,
  });

  final Color primary;
  final Color primarySoft;
  final Color secondary;
  final Color accent;
  final Color soft;
  final Color card;
  final Color textPrimary;
  final Color textSecondary;
  final Color calendarCardBackground;
  final Color planCardBackground;
  final Color expenseCardBackground;
  final Color lifeListCardBackground;
  final Color profileIconBackground;
  final Color sectionTitleColor;
  final Color bottomNavSelected;
  final Color bottomNavUnselected;
  final Color illustrationColor;
  final LinearGradient pageGradient;

  @override
  WarmThemeColors copyWith({
    Color? primary,
    Color? primarySoft,
    Color? secondary,
    Color? accent,
    Color? soft,
    Color? card,
    Color? textPrimary,
    Color? textSecondary,
    Color? calendarCardBackground,
    Color? planCardBackground,
    Color? expenseCardBackground,
    Color? lifeListCardBackground,
    Color? profileIconBackground,
    Color? sectionTitleColor,
    Color? bottomNavSelected,
    Color? bottomNavUnselected,
    Color? illustrationColor,
    LinearGradient? pageGradient,
  }) {
    return WarmThemeColors(
      primary: primary ?? this.primary,
      primarySoft: primarySoft ?? this.primarySoft,
      secondary: secondary ?? this.secondary,
      accent: accent ?? this.accent,
      soft: soft ?? this.soft,
      card: card ?? this.card,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      calendarCardBackground:
          calendarCardBackground ?? this.calendarCardBackground,
      planCardBackground: planCardBackground ?? this.planCardBackground,
      expenseCardBackground:
          expenseCardBackground ?? this.expenseCardBackground,
      lifeListCardBackground:
          lifeListCardBackground ?? this.lifeListCardBackground,
      profileIconBackground:
          profileIconBackground ?? this.profileIconBackground,
      sectionTitleColor: sectionTitleColor ?? this.sectionTitleColor,
      bottomNavSelected: bottomNavSelected ?? this.bottomNavSelected,
      bottomNavUnselected: bottomNavUnselected ?? this.bottomNavUnselected,
      illustrationColor: illustrationColor ?? this.illustrationColor,
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
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t) ?? primarySoft,
      secondary: Color.lerp(secondary, other.secondary, t) ?? secondary,
      accent: Color.lerp(accent, other.accent, t) ?? accent,
      soft: Color.lerp(soft, other.soft, t) ?? soft,
      card: Color.lerp(card, other.card, t) ?? card,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t) ?? textPrimary,
      textSecondary:
          Color.lerp(textSecondary, other.textSecondary, t) ?? textSecondary,
      calendarCardBackground:
          Color.lerp(calendarCardBackground, other.calendarCardBackground, t) ??
          calendarCardBackground,
      planCardBackground:
          Color.lerp(planCardBackground, other.planCardBackground, t) ??
          planCardBackground,
      expenseCardBackground:
          Color.lerp(expenseCardBackground, other.expenseCardBackground, t) ??
          expenseCardBackground,
      lifeListCardBackground:
          Color.lerp(lifeListCardBackground, other.lifeListCardBackground, t) ??
          lifeListCardBackground,
      profileIconBackground:
          Color.lerp(profileIconBackground, other.profileIconBackground, t) ??
          profileIconBackground,
      sectionTitleColor:
          Color.lerp(sectionTitleColor, other.sectionTitleColor, t) ??
          sectionTitleColor,
      bottomNavSelected:
          Color.lerp(bottomNavSelected, other.bottomNavSelected, t) ??
          bottomNavSelected,
      bottomNavUnselected:
          Color.lerp(bottomNavUnselected, other.bottomNavUnselected, t) ??
          bottomNavUnselected,
      illustrationColor:
          Color.lerp(illustrationColor, other.illustrationColor, t) ??
          illustrationColor,
      pageGradient:
          LinearGradient.lerp(pageGradient, other.pageGradient, t) ??
          pageGradient,
    );
  }
}

class AppTheme {
  const AppTheme._();

  static ThemeData light([String themeKey = 'minimalWhite']) {
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
          .apply(
            bodyColor: warmColors.textPrimary,
            displayColor: warmColors.textPrimary,
          )
          .copyWith(
            headlineSmall: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              height: 1.2,
              color: warmColors.textPrimary,
            ),
            titleLarge: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.25,
              color: warmColors.textPrimary,
            ),
            titleMedium: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              height: 1.35,
              color: warmColors.textPrimary,
            ),
            bodyLarge: TextStyle(color: warmColors.textPrimary),
            bodyMedium: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: warmColors.textPrimary,
            ),
            bodySmall: TextStyle(color: warmColors.textSecondary),
          ),
      dividerTheme: DividerThemeData(
        color: warmColors.primarySoft.withValues(alpha: 0.72),
        thickness: 1,
        space: 1,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: warmColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: warmColors.primarySoft,
          disabledForegroundColor: warmColors.textSecondary,
          elevation: 0,
          minimumSize: const Size(0, 50),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: warmColors.primary,
          side: BorderSide(color: warmColors.primary.withValues(alpha: 0.32)),
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
        indicatorColor: warmColors.primarySoft.withValues(alpha: 0.9),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected
                ? warmColors.bottomNavSelected
                : warmColors.bottomNavUnselected,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected
                ? warmColors.bottomNavSelected
                : warmColors.bottomNavUnselected,
            size: selected ? 25 : 23,
          );
        }),
      ),
    );
  }

  static WarmThemeColors _warmColorsFor(String themeKey) {
    final option = ProfileThemeUtils.byKey(themeKey);

    return WarmThemeColors(
      primary: option.primary,
      primarySoft: option.primarySoft,
      secondary: option.secondary,
      accent: option.accent,
      soft: option.backgroundStart,
      card: option.cardBackground,
      textPrimary: option.textPrimary,
      textSecondary: option.textSecondary,
      calendarCardBackground: option.calendarCardBackground,
      planCardBackground: option.planCardBackground,
      expenseCardBackground: option.expenseCardBackground,
      lifeListCardBackground: option.lifeListCardBackground,
      profileIconBackground: option.profileIconBackground,
      sectionTitleColor: option.sectionTitleColor,
      bottomNavSelected: option.bottomNavSelected,
      bottomNavUnselected: option.bottomNavUnselected,
      illustrationColor: option.illustrationColor,
      pageGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          option.backgroundStart,
          option.backgroundEnd,
          option.cardBackground.withValues(alpha: 0.96),
        ],
      ),
    );
  }
}
