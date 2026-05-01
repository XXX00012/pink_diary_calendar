import 'package:flutter/material.dart';
import 'package:pink_diary_calendar/theme/app_colors.dart';

class ProfileThemeOption {
  const ProfileThemeOption({
    required this.key,
    required this.name,
    required this.description,
    required this.primary,
    required this.secondary,
    required this.soft,
  });

  final String key;
  final String name;
  final String description;
  final Color primary;
  final Color secondary;
  final Color soft;
}

class ProfileThemeUtils {
  const ProfileThemeUtils._();

  static const List<ProfileThemeOption> options = [
    ProfileThemeOption(
      key: 'pink',
      name: '默认粉',
      description: '温柔粉、浅玫瑰、奶白',
      primary: AppColors.roseDeep,
      secondary: AppColors.rose,
      soft: AppColors.blush,
    ),
    ProfileThemeOption(
      key: 'cream',
      name: '奶油白',
      description: '奶白、浅米、淡金',
      primary: Color(0xFFD2A85F),
      secondary: AppColors.butter,
      soft: Color(0xFFFFF8E7),
    ),
    ProfileThemeOption(
      key: 'lavender',
      name: '浅紫',
      description: '浅紫、薰衣草、奶白',
      primary: AppColors.lavenderDeep,
      secondary: AppColors.lavender,
      soft: Color(0xFFF4EEFF),
    ),
    ProfileThemeOption(
      key: 'peach',
      name: '蜜桃橙',
      description: '蜜桃、奶白、暖杏',
      primary: Color(0xFFD9896F),
      secondary: AppColors.peach,
      soft: Color(0xFFFFF0E8),
    ),
    ProfileThemeOption(
      key: 'sage',
      name: '薄荷绿',
      description: '薄荷、奶白、浅绿',
      primary: Color(0xFF78A882),
      secondary: AppColors.sage,
      soft: Color(0xFFF0FAF2),
    ),
  ];

  static ProfileThemeOption byKey(String key) {
    return options.firstWhere(
      (option) => option.key == key,
      orElse: () => options.first,
    );
  }
}
