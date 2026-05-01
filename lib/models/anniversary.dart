class Anniversary {
  const Anniversary({
    required this.id,
    required this.title,
    required this.date,
    required this.type,
    required this.repeatYearly,
    required this.remindBeforeDays,
    required this.themeColor,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String date;
  final String type;
  final bool repeatYearly;
  final int remindBeforeDays;
  final String themeColor;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;

  Anniversary copyWith({
    String? id,
    String? title,
    String? date,
    String? type,
    bool? repeatYearly,
    int? remindBeforeDays,
    String? themeColor,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Anniversary(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
      type: type ?? this.type,
      repeatYearly: repeatYearly ?? this.repeatYearly,
      remindBeforeDays: remindBeforeDays ?? this.remindBeforeDays,
      themeColor: themeColor ?? this.themeColor,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date,
      'type': type,
      'repeatYearly': repeatYearly,
      'remindBeforeDays': remindBeforeDays,
      'themeColor': themeColor,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Anniversary.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return Anniversary(
      id: json['id'] as String? ?? 'anniversary-${now.microsecondsSinceEpoch}',
      title: json['title'] as String? ?? '',
      date: json['date'] as String? ?? '',
      type: json['type'] as String? ?? '纪念日',
      repeatYearly: json['repeatYearly'] as bool? ?? false,
      remindBeforeDays: _readInt(json['remindBeforeDays']),
      themeColor: json['themeColor'] as String? ?? 'blush',
      note: json['note'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? now,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? now,
    );
  }

  static int _readInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
