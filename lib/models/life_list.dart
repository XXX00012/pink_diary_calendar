class LifeList {
  const LifeList({
    required this.id,
    required this.type,
    required this.title,
    required this.items,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String type;
  final String title;
  final List<LifeListItem> items;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;

  int get completedCount => items.where((item) => item.done).length;
  int get totalCount => items.length;
  int get unfinishedCount => items.where((item) => !item.done).length;

  LifeList copyWith({
    String? id,
    String? type,
    String? title,
    List<LifeListItem>? items,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LifeList(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      items: items ?? this.items,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'items': items.map((item) => item.toJson()).toList(),
      'note': note,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory LifeList.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return LifeList(
      id: json['id'] as String? ?? 'life-list-${now.microsecondsSinceEpoch}',
      type: json['type'] as String? ?? LifeListTypes.shopping,
      title: json['title'] as String? ?? '',
      items: _readItems(json['items']),
      note: json['note'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? now,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? now,
    );
  }

  static List<LifeListItem> _readItems(Object? value) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map>()
        .map((item) => LifeListItem.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}

class LifeListItem {
  const LifeListItem({
    required this.id,
    required this.text,
    required this.done,
    required this.createdAt,
  });

  final String id;
  final String text;
  final bool done;
  final DateTime createdAt;

  LifeListItem copyWith({
    String? id,
    String? text,
    bool? done,
    DateTime? createdAt,
  }) {
    return LifeListItem(
      id: id ?? this.id,
      text: text ?? this.text,
      done: done ?? this.done,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'done': done,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory LifeListItem.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return LifeListItem(
      id: json['id'] as String? ?? 'life-item-${now.microsecondsSinceEpoch}',
      text: json['text'] as String? ?? '',
      done: json['done'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? now,
    );
  }
}

class LifeListTypes {
  const LifeListTypes._();

  static const String shopping = 'shopping';
  static const String study = 'study';
  static const String travel = 'travel';
}
