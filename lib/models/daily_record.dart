class DailyRecord {
  const DailyRecord({
    required this.date,
    required this.text,
    required this.updatedAt,
    this.images = const [],
    this.expenses = const [],
    this.littleJoys = const [],
    this.reminders = const [],
  });

  final String date;
  final String text;
  final DateTime updatedAt;
  final List<String> images;
  final List<ExpenseEntry> expenses;
  final List<LittleJoyEntry> littleJoys;
  final List<dynamic> reminders;

  bool get hasText => text.trim().isNotEmpty;
  bool get hasContent =>
      hasText ||
      images.isNotEmpty ||
      expenses.isNotEmpty ||
      littleJoys.isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'text': text,
      'updatedAt': updatedAt.toIso8601String(),
      'images': images,
      'expenses': expenses.map((entry) => entry.toJson()).toList(),
      'littleJoys': littleJoys.map((entry) => entry.toJson()).toList(),
      'reminders': reminders,
    };
  }

  factory DailyRecord.fromJson(Map<String, dynamic> json) {
    return DailyRecord(
      date: json['date'] as String? ?? '',
      text: json['text'] as String? ?? '',
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      images: _readStringList(json['images']),
      expenses: _readExpenseEntries(json['expenses']),
      littleJoys: _readLittleJoyEntries(json['littleJoys']),
      reminders: json['reminders'] as List<dynamic>? ?? const [],
    );
  }

  static List<String> _readStringList(Object? value) {
    if (value is! List) {
      return const [];
    }
    return value.whereType<String>().toList();
  }

  static List<ExpenseEntry> _readExpenseEntries(Object? value) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map>()
        .map((entry) => ExpenseEntry.fromJson(Map<String, dynamic>.from(entry)))
        .toList();
  }

  static List<LittleJoyEntry> _readLittleJoyEntries(Object? value) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map>()
        .map(
          (entry) => LittleJoyEntry.fromJson(Map<String, dynamic>.from(entry)),
        )
        .toList();
  }
}

class ExpenseEntry {
  const ExpenseEntry({
    required this.id,
    required this.amount,
    required this.note,
    required this.type,
    required this.createdAt,
  });

  final String id;
  final double amount;
  final String note;
  final String type;
  final DateTime createdAt;

  bool get isIncome => type == 'income';
  String get displayNote => note.trim().isEmpty ? '一笔记录' : note.trim();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'note': note,
      'type': type,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ExpenseEntry.fromJson(Map<String, dynamic> json) {
    final rawAmount = json['amount'];
    return ExpenseEntry(
      id: json['id'] as String? ?? '',
      amount: rawAmount is num
          ? rawAmount.toDouble()
          : double.tryParse(rawAmount?.toString() ?? '') ?? 0,
      note: json['note'] as String? ?? '',
      type: (json['type'] as String?) == 'income' ? 'income' : 'expense',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class LittleJoyEntry {
  const LittleJoyEntry({
    required this.id,
    required this.text,
    required this.createdAt,
  });

  final String id;
  final String text;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {'id': id, 'text': text, 'createdAt': createdAt.toIso8601String()};
  }

  factory LittleJoyEntry.fromJson(Map<String, dynamic> json) {
    return LittleJoyEntry(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
