class DailyRecord {
  const DailyRecord({
    required this.date,
    required this.text,
    required this.updatedAt,
    this.images = const [],
    this.expenses = const [],
    this.plans = const [],
    this.reminders = const [],
  });

  final String date;
  final String text;
  final DateTime updatedAt;
  final List<String> images;
  final List<ExpenseEntry> expenses;
  final List<PlanEntry> plans;
  final List<dynamic> reminders;

  bool get hasText => text.trim().isNotEmpty;
  bool get hasContent =>
      hasText || images.isNotEmpty || expenses.isNotEmpty || plans.isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'text': text,
      'updatedAt': updatedAt.toIso8601String(),
      'images': images,
      'expenses': expenses.map((entry) => entry.toJson()).toList(),
      'plans': plans.map((entry) => entry.toJson()).toList(),
      'littleJoys': const [],
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
      plans: _readPlanEntries(json['plans'], json['littleJoys']),
      reminders: _readDynamicList(json['reminders']),
    );
  }

  static List<String> _readStringList(Object? value) {
    if (value is! List) {
      return const [];
    }
    return value.whereType<String>().toList();
  }

  static List<dynamic> _readDynamicList(Object? value) {
    if (value is! List) {
      return const [];
    }
    return List<dynamic>.from(value);
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

  static List<PlanEntry> _readPlanEntries(Object? plans, Object? littleJoys) {
    final planSource = plans is List ? plans : const [];
    final planEntries = planSource
        .whereType<Map>()
        .map((entry) => PlanEntry.fromJson(Map<String, dynamic>.from(entry)))
        .toList();

    if (planEntries.isNotEmpty || littleJoys is! List) {
      return planEntries;
    }

    return littleJoys
        .whereType<Map>()
        .map((entry) => PlanEntry.fromLegacyLittleJoy(entry))
        .where((entry) => entry.text.trim().isNotEmpty)
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

class PlanEntry {
  const PlanEntry({
    required this.id,
    required this.text,
    required this.note,
    required this.createdAt,
  });

  final String id;
  final String text;
  final String note;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PlanEntry.fromJson(Map<String, dynamic> json) {
    return PlanEntry(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      note: json['note'] as String? ?? '',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  factory PlanEntry.fromLegacyLittleJoy(Map<dynamic, dynamic> json) {
    final normalizedJson = Map<String, dynamic>.from(json);
    final text = normalizedJson['text'] as String? ?? '';
    final createdAt =
        DateTime.tryParse(normalizedJson['createdAt'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final id = normalizedJson['id'] as String?;
    return PlanEntry(
      id: id == null || id.isEmpty
          ? 'legacy-plan-${createdAt.microsecondsSinceEpoch}-${text.hashCode}'
          : id,
      text: text,
      note: '',
      createdAt: createdAt,
    );
  }
}
