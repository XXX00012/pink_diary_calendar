class LifeList {
  const LifeList({
    required this.id,
    required String type,
    String? categoryId,
    required this.title,
    required this.items,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  }) : type = categoryId ?? type;

  final String id;
  final String type;
  String get categoryId => type;
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
    String? categoryId,
    String? title,
    List<LifeListItem>? items,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LifeList(
      id: id ?? this.id,
      type: categoryId ?? type ?? this.type,
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
      'categoryId': categoryId,
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
      type:
          json['categoryId'] as String? ??
          json['type'] as String? ??
          LifeListTypes.shopping,
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

class LifeListCategory {
  const LifeListCategory({
    required this.id,
    required this.name,
    required this.icon,
    required this.colorKey,
    required this.isBuiltIn,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String icon;
  final String colorKey;
  final bool isBuiltIn;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'colorKey': colorKey,
      'isBuiltIn': isBuiltIn,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory LifeListCategory.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return LifeListCategory(
      id: json['id'] as String? ?? 'category-${now.microsecondsSinceEpoch}',
      name: json['name'] as String? ?? '自定义分类',
      icon: json['icon'] as String? ?? 'list',
      colorKey: json['colorKey'] as String? ?? 'blue',
      isBuiltIn: json['isBuiltIn'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? now,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ?? now,
    );
  }

  static List<LifeListCategory> builtInCategories() {
    final zero = DateTime.fromMillisecondsSinceEpoch(0);
    return [
      LifeListCategory(
        id: LifeListTypes.shopping,
        name: '购物清单',
        icon: 'shopping',
        colorKey: 'sand',
        isBuiltIn: true,
        createdAt: zero,
        updatedAt: zero,
      ),
      LifeListCategory(
        id: LifeListTypes.study,
        name: '学习计划',
        icon: 'book',
        colorKey: 'green',
        isBuiltIn: true,
        createdAt: zero,
        updatedAt: zero,
      ),
      LifeListCategory(
        id: LifeListTypes.travel,
        name: '旅行攻略',
        icon: 'travel',
        colorKey: 'blue',
        isBuiltIn: true,
        createdAt: zero,
        updatedAt: zero,
      ),
    ];
  }
}
