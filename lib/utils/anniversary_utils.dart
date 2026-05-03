import 'package:flutter/material.dart';
import 'package:pink_diary_calendar/models/anniversary.dart';
import 'package:pink_diary_calendar/theme/app_colors.dart';
import 'package:pink_diary_calendar/utils/calendar_utils.dart';

class AnniversaryDateInfo {
  const AnniversaryDateInfo({
    required this.label,
    required this.days,
    required this.targetDate,
    required this.isToday,
    required this.isPast,
  });

  final String label;
  final int days;
  final DateTime targetDate;
  final bool isToday;
  final bool isPast;
}

class AnniversaryThemeOption {
  const AnniversaryThemeOption({
    required this.id,
    required this.label,
    required this.color,
    required this.softColor,
  });

  final String id;
  final String label;
  final Color color;
  final Color softColor;
}

class AnniversaryUtils {
  const AnniversaryUtils._();

  static const List<String> types = [
    '生日',
    '纪念日',
    '旅行',
    '考试',
    '生活',
    '工作',
    '自定义',
  ];

  static const List<int> reminderOptions = [-1, 0, 1, 3, 7];

  static const List<AnniversaryThemeOption> themeOptions = [
    AnniversaryThemeOption(
      id: 'blush',
      label: '桃雾粉',
      color: AppColors.roseDeep,
      softColor: AppColors.blush,
    ),
    AnniversaryThemeOption(
      id: 'rose',
      label: '浅玫瑰',
      color: AppColors.rose,
      softColor: Color(0xFFFFEEF4),
    ),
    AnniversaryThemeOption(
      id: 'lavender',
      label: '浅紫',
      color: AppColors.lavenderDeep,
      softColor: Color(0xFFF3ECFF),
    ),
    AnniversaryThemeOption(
      id: 'peach',
      label: '蜜桃橙',
      color: AppColors.peach,
      softColor: Color(0xFFFFF0E8),
    ),
    AnniversaryThemeOption(
      id: 'sage',
      label: '薄荷绿',
      color: AppColors.sage,
      softColor: Color(0xFFF0FAF2),
    ),
    AnniversaryThemeOption(
      id: 'butter',
      label: '奶油黄',
      color: Color(0xFFD4AA4C),
      softColor: Color(0xFFFFF7D8),
    ),
    AnniversaryThemeOption(
      id: 'blue',
      label: '浅蓝色',
      color: Color(0xFF78A4C7),
      softColor: Color(0xFFEFF8FF),
    ),
    AnniversaryThemeOption(
      id: 'milk',
      label: '奶油白',
      color: Color(0xFFC7A978),
      softColor: AppColors.milk,
    ),
  ];

  static String typeIcon(String type) {
    return switch (type) {
      '生日' => '🎂',
      '纪念日' => '💗',
      '旅行' => '✈️',
      '考试' => '📖',
      '生活' => '🌷',
      '工作' => '✨',
      _ => '⭐',
    };
  }

  static bool defaultRepeatYearly(String type) {
    return type == '生日';
  }

  static AnniversaryThemeOption themeById(String id) {
    return themeOptions.firstWhere(
      (option) => option.id == id,
      orElse: () => themeOptions.first,
    );
  }

  static DateTime? parseDateKey(String dateKey) {
    final parts = dateKey.split('-');
    if (parts.length != 3) {
      return null;
    }

    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) {
      return null;
    }

    return DateTime(year, month, day);
  }

  static AnniversaryDateInfo dateInfo(
    Anniversary anniversary, {
    DateTime? today,
  }) {
    final baseDate = parseDateKey(anniversary.date);
    final normalizedToday = CalendarUtils.dateOnly(today ?? DateTime.now());
    if (baseDate == null) {
      return AnniversaryDateInfo(
        label: '日期待确认',
        days: 0,
        targetDate: normalizedToday,
        isToday: false,
        isPast: false,
      );
    }

    if (anniversary.repeatYearly) {
      var nextDate = DateTime(
        normalizedToday.year,
        baseDate.month,
        baseDate.day,
      );
      if (nextDate.isBefore(normalizedToday)) {
        nextDate = DateTime(
          normalizedToday.year + 1,
          baseDate.month,
          baseDate.day,
        );
      }
      final days = nextDate.difference(normalizedToday).inDays;
      return AnniversaryDateInfo(
        label: days == 0 ? '就是今天' : '还有 $days 天',
        days: days,
        targetDate: nextDate,
        isToday: days == 0,
        isPast: false,
      );
    }

    final targetDate = CalendarUtils.dateOnly(baseDate);
    final days = targetDate.difference(normalizedToday).inDays;
    if (days == 0) {
      return AnniversaryDateInfo(
        label: '就是今天',
        days: 0,
        targetDate: targetDate,
        isToday: true,
        isPast: false,
      );
    }

    if (days > 0) {
      return AnniversaryDateInfo(
        label: '还有 $days 天',
        days: days,
        targetDate: targetDate,
        isToday: false,
        isPast: false,
      );
    }

    return AnniversaryDateInfo(
      label: '已经 ${days.abs()} 天',
      days: days.abs(),
      targetDate: targetDate,
      isToday: false,
      isPast: true,
    );
  }

  static List<Anniversary> sortAnniversaries(List<Anniversary> anniversaries) {
    final sorted = [...anniversaries];
    sorted.sort((first, second) {
      final firstInfo = dateInfo(first);
      final secondInfo = dateInfo(second);

      if (firstInfo.isPast != secondInfo.isPast) {
        return firstInfo.isPast ? 1 : -1;
      }

      final firstDistance = firstInfo.targetDate
          .difference(DateTime.now())
          .abs();
      final secondDistance = secondInfo.targetDate
          .difference(DateTime.now())
          .abs();
      return firstDistance.compareTo(secondDistance);
    });
    return sorted;
  }

  static bool isOneTimePast(Anniversary anniversary, {DateTime? today}) {
    return !anniversary.repeatYearly &&
        dateInfo(anniversary, today: today).isPast;
  }

  static String reminderLabel(int days) {
    return switch (days) {
      0 => '当天',
      1 => '提前 1 天',
      3 => '提前 3 天',
      7 => '提前 7 天',
      _ => '不提醒',
    };
  }

  static bool matchesCalendarDate(Anniversary anniversary, DateTime date) {
    final anniversaryDate = parseDateKey(anniversary.date);
    if (anniversaryDate == null) {
      return false;
    }

    if (anniversary.repeatYearly) {
      return anniversaryDate.month == date.month &&
          anniversaryDate.day == date.day;
    }

    return CalendarUtils.isSameDay(anniversaryDate, date);
  }
}
