import 'package:flutter/material.dart';

class ProfileThemeOption {
  const ProfileThemeOption({
    required this.key,
    required this.name,
    required this.description,
    required this.backgroundStart,
    required this.backgroundEnd,
    required this.primary,
    required this.primarySoft,
    required this.secondary,
    required this.accent,
    required this.textPrimary,
    required this.textSecondary,
    required this.cardBackground,
    required this.calendarCardBackground,
    required this.planCardBackground,
    required this.expenseCardBackground,
    required this.lifeListCardBackground,
    required this.profileIconBackground,
    required this.sectionTitleColor,
    required this.bottomNavSelected,
    required this.bottomNavUnselected,
    required this.illustrationColor,
  });

  final String key;
  final String name;
  final String description;
  final Color backgroundStart;
  final Color backgroundEnd;
  final Color primary;
  final Color primarySoft;
  final Color secondary;
  final Color accent;
  final Color textPrimary;
  final Color textSecondary;
  final Color cardBackground;
  final Color calendarCardBackground;
  final Color planCardBackground;
  final Color expenseCardBackground;
  final Color lifeListCardBackground;
  final Color profileIconBackground;
  final Color sectionTitleColor;
  final Color bottomNavSelected;
  final Color bottomNavUnselected;
  final Color illustrationColor;

  // Compatibility alias used by older pages while they are gradually moved to
  // the fuller palette.
  Color get soft => backgroundStart;
}

class ProfileThemeUtils {
  const ProfileThemeUtils._();

  static const List<ProfileThemeOption> options = [
    ProfileThemeOption(
      key: 'minimalWhite',
      name: '简约白',
      description: '米白、灰蓝、浅绿',
      backgroundStart: Color(0xFFFAF8F2),
      backgroundEnd: Color(0xFFFBFAF5),
      primary: Color(0xFF7FA3AF),
      primarySoft: Color(0xFFEAF5F8),
      secondary: Color(0xFF86A8A0),
      accent: Color(0xFFC4A66A),
      textPrimary: Color(0xFF3D3A38),
      textSecondary: Color(0xFF8B8582),
      cardBackground: Color(0xFFFFFFFF),
      calendarCardBackground: Color(0xFFFFFFFF),
      planCardBackground: Color(0xFFE7F3F7),
      expenseCardBackground: Color(0xFFEAF6EE),
      lifeListCardBackground: Color(0xFFF8F1E3),
      profileIconBackground: Color(0xFFEAF5F8),
      sectionTitleColor: Color(0xFF6F8F98),
      bottomNavSelected: Color(0xFF7FA3AF),
      bottomNavUnselected: Color(0xFF9B9290),
      illustrationColor: Color(0xFF86A8A0),
    ),
    ProfileThemeOption(
      key: 'pink',
      name: '桃雾粉',
      description: '雾粉、浅玫瑰、奶白',
      backgroundStart: Color(0xFFFFF6F8),
      backgroundEnd: Color(0xFFFFFBF8),
      primary: Color(0xFFC96F87),
      primarySoft: Color(0xFFFFEEF2),
      secondary: Color(0xFFE9A8B6),
      accent: Color(0xFFD9A3B0),
      textPrimary: Color(0xFF4B4042),
      textSecondary: Color(0xFF9A8589),
      cardBackground: Color(0xFFFFFEFC),
      calendarCardBackground: Color(0xFFFFF0F4),
      planCardBackground: Color(0xFFF7EAF2),
      expenseCardBackground: Color(0xFFFFF3EC),
      lifeListCardBackground: Color(0xFFFFF7E8),
      profileIconBackground: Color(0xFFFFEEF2),
      sectionTitleColor: Color(0xFFC96F87),
      bottomNavSelected: Color(0xFFC96F87),
      bottomNavUnselected: Color(0xFF9B8D90),
      illustrationColor: Color(0xFFE1A0B0),
    ),
    ProfileThemeOption(
      key: 'softRed',
      name: '淡红色',
      description: '淡红、奶白、浅玫瑰',
      backgroundStart: Color(0xFFFFF3F1),
      backgroundEnd: Color(0xFFFFFEFC),
      primary: Color(0xFFC87577),
      primarySoft: Color(0xFFFFEAE8),
      secondary: Color(0xFFE6A3A4),
      accent: Color(0xFFD5A0A1),
      textPrimary: Color(0xFF4A3D3D),
      textSecondary: Color(0xFF967F7F),
      cardBackground: Color(0xFFFFFEFC),
      calendarCardBackground: Color(0xFFFFEFEA),
      planCardBackground: Color(0xFFFFF1EC),
      expenseCardBackground: Color(0xFFF5F1E6),
      lifeListCardBackground: Color(0xFFF8F3EA),
      profileIconBackground: Color(0xFFFFEAE8),
      sectionTitleColor: Color(0xFFB56E70),
      bottomNavSelected: Color(0xFFC87577),
      bottomNavUnselected: Color(0xFF9A8A88),
      illustrationColor: Color(0xFFD99A9B),
    ),
    ProfileThemeOption(
      key: 'cream',
      name: '奶油黄',
      description: '奶黄、浅米、淡金',
      backgroundStart: Color(0xFFFFFBF1),
      backgroundEnd: Color(0xFFFFFEFA),
      primary: Color(0xFFD2A85F),
      primarySoft: Color(0xFFFFF3D8),
      secondary: Color(0xFFE8D49B),
      accent: Color(0xFFC7A978),
      textPrimary: Color(0xFF463F35),
      textSecondary: Color(0xFF928879),
      cardBackground: Color(0xFFFFFEFC),
      calendarCardBackground: Color(0xFFFFF4D7),
      planCardBackground: Color(0xFFF8F0D9),
      expenseCardBackground: Color(0xFFF2F5E6),
      lifeListCardBackground: Color(0xFFFFF7E7),
      profileIconBackground: Color(0xFFFFF3D8),
      sectionTitleColor: Color(0xFFB28B45),
      bottomNavSelected: Color(0xFFD2A85F),
      bottomNavUnselected: Color(0xFF9A9285),
      illustrationColor: Color(0xFFC8AD6B),
    ),
    ProfileThemeOption(
      key: 'lavender',
      name: '浅紫',
      description: '浅紫、薰衣草、奶白',
      backgroundStart: Color(0xFFF5F0FF),
      backgroundEnd: Color(0xFFFFFAF5),
      primary: Color(0xFF967AC8),
      primarySoft: Color(0xFFF0E9FF),
      secondary: Color(0xFFD8C9EE),
      accent: Color(0xFFBBA7DD),
      textPrimary: Color(0xFF423B4B),
      textSecondary: Color(0xFF8B8194),
      cardBackground: Color(0xFFFFFEFC),
      calendarCardBackground: Color(0xFFF2ECFF),
      planCardBackground: Color(0xFFF0EEFF),
      expenseCardBackground: Color(0xFFF2F6EC),
      lifeListCardBackground: Color(0xFFF8F2E7),
      profileIconBackground: Color(0xFFF0E9FF),
      sectionTitleColor: Color(0xFF8067AE),
      bottomNavSelected: Color(0xFF967AC8),
      bottomNavUnselected: Color(0xFF928C98),
      illustrationColor: Color(0xFFA894D0),
    ),
    ProfileThemeOption(
      key: 'peach',
      name: '蜜桃橙',
      description: '蜜桃、奶白、暖杏',
      backgroundStart: Color(0xFFFFF0E8),
      backgroundEnd: Color(0xFFFFFAF5),
      primary: Color(0xFFD9896F),
      primarySoft: Color(0xFFFFE9DC),
      secondary: Color(0xFFF7B99D),
      accent: Color(0xFFE9A67E),
      textPrimary: Color(0xFF493D37),
      textSecondary: Color(0xFF957F74),
      cardBackground: Color(0xFFFFFEFC),
      calendarCardBackground: Color(0xFFFFEDE1),
      planCardBackground: Color(0xFFFFF1E8),
      expenseCardBackground: Color(0xFFF2F6EA),
      lifeListCardBackground: Color(0xFFFFF5DF),
      profileIconBackground: Color(0xFFFFE9DC),
      sectionTitleColor: Color(0xFFC77961),
      bottomNavSelected: Color(0xFFD9896F),
      bottomNavUnselected: Color(0xFF988B84),
      illustrationColor: Color(0xFFE8A98F),
    ),
    ProfileThemeOption(
      key: 'sage',
      name: '薄荷绿',
      description: '薄荷、奶白、浅绿',
      backgroundStart: Color(0xFFF0FAF2),
      backgroundEnd: Color(0xFFFFFEFC),
      primary: Color(0xFF78A882),
      primarySoft: Color(0xFFE8F6EC),
      secondary: Color(0xFFAED8B6),
      accent: Color(0xFF93BE9B),
      textPrimary: Color(0xFF39443B),
      textSecondary: Color(0xFF7F8D82),
      cardBackground: Color(0xFFFFFEFC),
      calendarCardBackground: Color(0xFFEAF7EE),
      planCardBackground: Color(0xFFEAF4F8),
      expenseCardBackground: Color(0xFFE7F5EC),
      lifeListCardBackground: Color(0xFFF7F2E5),
      profileIconBackground: Color(0xFFE8F6EC),
      sectionTitleColor: Color(0xFF6B9172),
      bottomNavSelected: Color(0xFF78A882),
      bottomNavUnselected: Color(0xFF879086),
      illustrationColor: Color(0xFF8DBE97),
    ),
    ProfileThemeOption(
      key: 'blue',
      name: '浅蓝色',
      description: '浅蓝、奶白、灰蓝',
      backgroundStart: Color(0xFFEFF8FF),
      backgroundEnd: Color(0xFFFFFEFC),
      primary: Color(0xFF6F9FC4),
      primarySoft: Color(0xFFE8F4FC),
      secondary: Color(0xFFBFDDF2),
      accent: Color(0xFF8FB8D2),
      textPrimary: Color(0xFF39424A),
      textSecondary: Color(0xFF7B8994),
      cardBackground: Color(0xFFFFFEFC),
      calendarCardBackground: Color(0xFFE8F4FC),
      planCardBackground: Color(0xFFE6F2F8),
      expenseCardBackground: Color(0xFFEAF5EE),
      lifeListCardBackground: Color(0xFFF6F1E6),
      profileIconBackground: Color(0xFFE8F4FC),
      sectionTitleColor: Color(0xFF5E879D),
      bottomNavSelected: Color(0xFF6F9FC4),
      bottomNavUnselected: Color(0xFF87909A),
      illustrationColor: Color(0xFF8FB8D2),
    ),
  ];

  static ProfileThemeOption byKey(String key) {
    final normalizedKey = switch (key) {
      'defaultPink' || 'rosePink' || 'peachPink' => 'pink',
      'simpleWhite' || 'white' => 'minimalWhite',
      _ => key,
    };

    return options.firstWhere(
      (option) => option.key == normalizedKey,
      orElse: () => options.first,
    );
  }
}
