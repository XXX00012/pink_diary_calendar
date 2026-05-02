import 'package:pink_diary_calendar/models/daily_record.dart';
import 'package:pink_diary_calendar/utils/calendar_utils.dart';

class ExpenseSummary {
  const ExpenseSummary({
    required this.totalExpense,
    required this.totalIncome,
    required this.entryCount,
  });

  final double totalExpense;
  final double totalIncome;
  final int entryCount;

  double get balance => totalIncome - totalExpense;
  bool get hasEntries => entryCount > 0;
}

class ExpenseSummaryResult {
  const ExpenseSummaryResult({required this.summary, required this.groups});

  final ExpenseSummary summary;
  final List<ExpenseDateGroup> groups;
}

class ExpenseDateGroup {
  const ExpenseDateGroup({
    required this.date,
    required this.dateKey,
    required this.entries,
  });

  final DateTime date;
  final String dateKey;
  final List<ExpenseEntry> entries;
}

class ExpenseDateRange {
  const ExpenseDateRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}

class ExpenseSummaryUtils {
  const ExpenseSummaryUtils._();

  static ExpenseDateRange monthRange(DateTime month) {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1, 0);
    return ExpenseDateRange(start: start, end: end);
  }

  static ExpenseSummary currentMonthSummary(
    Map<String, DailyRecord> records, {
    DateTime? today,
  }) {
    final range = monthRange(today ?? DateTime.now());
    return summarize(records, start: range.start, end: range.end).summary;
  }

  static ExpenseSummaryResult summarize(
    Map<String, DailyRecord> records, {
    required DateTime start,
    required DateTime end,
  }) {
    final normalizedStart = CalendarUtils.dateOnly(start);
    final normalizedEnd = CalendarUtils.dateOnly(end);
    final groups = <ExpenseDateGroup>[];
    var totalExpense = 0.0;
    var totalIncome = 0.0;
    var entryCount = 0;

    for (final entry in records.entries) {
      final record = entry.value;
      final date = _parseDateKey(record.date) ?? _parseDateKey(entry.key);
      if (date == null ||
          date.isBefore(normalizedStart) ||
          date.isAfter(normalizedEnd) ||
          record.expenses.isEmpty) {
        continue;
      }

      final validEntries = <ExpenseEntry>[];
      for (final expense in record.expenses) {
        final amount = expense.amount.abs();
        if (amount <= 0) {
          continue;
        }

        validEntries.add(expense);
        entryCount++;
        if (expense.isIncome) {
          totalIncome += amount;
        } else {
          totalExpense += amount;
        }
      }

      if (validEntries.isNotEmpty) {
        groups.add(
          ExpenseDateGroup(
            date: date,
            dateKey: CalendarUtils.formatDateKey(date),
            entries: validEntries,
          ),
        );
      }
    }

    groups.sort((first, second) => second.date.compareTo(first.date));

    return ExpenseSummaryResult(
      summary: ExpenseSummary(
        totalExpense: totalExpense,
        totalIncome: totalIncome,
        entryCount: entryCount,
      ),
      groups: groups,
    );
  }

  static String formatMoney(double value) {
    return '¥${value.abs().toStringAsFixed(2)}';
  }

  static String formatCompactRange(ExpenseDateRange range) {
    return '${_formatDotDate(range.start)} - ${_formatDotDate(range.end)}';
  }

  static DateTime? _parseDateKey(String dateKey) {
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

  static String _formatDotDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}.$month.$day';
  }
}
