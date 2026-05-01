class CalendarDay {
  const CalendarDay({
    required this.date,
    required this.isCurrentMonth,
    required this.isToday,
  });

  final DateTime date;
  final bool isCurrentMonth;
  final bool isToday;
}

class CalendarUtils {
  const CalendarUtils._();

  static const List<String> _weekdayNames = [
    '星期一',
    '星期二',
    '星期三',
    '星期四',
    '星期五',
    '星期六',
    '星期日',
  ];

  static DateTime dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static DateTime monthOnly(DateTime date) {
    return DateTime(date.year, date.month);
  }

  static DateTime previousMonth(DateTime visibleMonth) {
    return DateTime(visibleMonth.year, visibleMonth.month - 1);
  }

  static DateTime nextMonth(DateTime visibleMonth) {
    return DateTime(visibleMonth.year, visibleMonth.month + 1);
  }

  static bool isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  static List<CalendarDay> buildMonthGrid(
    DateTime visibleMonth, {
    DateTime? today,
  }) {
    final monthStart = DateTime(visibleMonth.year, visibleMonth.month);
    final normalizedToday = dateOnly(today ?? DateTime.now());
    final firstWeekdayIndex = monthStart.weekday % 7;
    final gridStart = monthStart.subtract(Duration(days: firstWeekdayIndex));

    return List.generate(42, (index) {
      final date = gridStart.add(Duration(days: index));
      return CalendarDay(
        date: date,
        isCurrentMonth: date.month == visibleMonth.month,
        isToday: isSameDay(date, normalizedToday),
      );
    });
  }

  static String formatYearMonth(DateTime date) {
    return '${date.year} 年 ${date.month} 月';
  }

  static String formatMonthDay(DateTime date) {
    return '${date.month} 月 ${date.day} 日';
  }

  static String formatFullDate(DateTime date) {
    return '${date.year} 年 ${date.month} 月 ${date.day} 日';
  }

  static String formatDateKey(DateTime date) {
    final normalizedDate = dateOnly(date);
    final month = normalizedDate.month.toString().padLeft(2, '0');
    final day = normalizedDate.day.toString().padLeft(2, '0');
    return '${normalizedDate.year}-$month-$day';
  }

  static String formatMonthDayWithWeekday(DateTime date) {
    return '${date.month} 月 ${date.day} 日 ${weekdayName(date)}';
  }

  static String weekdayName(DateTime date) {
    return _weekdayNames[date.weekday - 1];
  }

  static String formatUpdatedTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
