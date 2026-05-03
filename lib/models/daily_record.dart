class DailyRecord {
  const DailyRecord({
    required this.date,
    required this.text,
    required this.updatedAt,
    this.images = const [],
    this.blocks = const [],
    this.attachmentImages = const [],
    this.expenses = const [],
    this.plans = const [],
    this.reminders = const [],
  });

  final String date;
  final String text;
  final DateTime updatedAt;
  final List<String> images;
  final List<DiaryBlock> blocks;
  final List<AttachmentImage> attachmentImages;
  final List<ExpenseEntry> expenses;
  final List<PlanEntry> plans;
  final List<dynamic> reminders;

  bool get hasText =>
      text.trim().isNotEmpty ||
      blocks.any((block) => block.isText && block.text.trim().isNotEmpty);
  bool get hasAnyContent =>
      text.trim().isNotEmpty ||
      images.isNotEmpty ||
      blocks.isNotEmpty ||
      attachmentImages.isNotEmpty ||
      expenses.isNotEmpty ||
      plans.isNotEmpty ||
      reminders.isNotEmpty;
  bool get hasContent => hasAnyContent;

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'text': text,
      'updatedAt': updatedAt.toIso8601String(),
      'images': images,
      'blocks': blocks.map((entry) => entry.toJson()).toList(),
      'attachmentImages':
          attachmentImages.map((entry) => entry.toJson()).toList(),
      'expenses': expenses.map((entry) => entry.toJson()).toList(),
      'plans': plans.map((entry) => entry.toJson()).toList(),
      'littleJoys': const [],
      'reminders': reminders,
    };
  }

  factory DailyRecord.fromJson(Map<String, dynamic> json) {
    final text = json['text'] as String? ?? '';
    final images = _readStringList(json['images']);
    final blocks = _readDiaryBlocks(json['blocks']);
    final attachmentImages = _readAttachmentImages(json['attachmentImages']);
    final hasBlockImages = blocks.any((b) => b.isImage);

    final effectiveBlocks = blocks.isNotEmpty
        ? blocks
        : _textOnlyLegacyBlocks(text);

    List<AttachmentImage> effectiveAttachments;
    if (attachmentImages.isNotEmpty) {
      effectiveAttachments = attachmentImages;
    } else if (images.isNotEmpty && !hasBlockImages) {
      effectiveAttachments = _legacyAttachmentImages(images);
    } else {
      effectiveAttachments = const [];
    }

    return DailyRecord(
      date: json['date'] as String? ?? '',
      text: text,
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      images: images,
      blocks: effectiveBlocks,
      attachmentImages: effectiveAttachments,
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

  static List<DiaryBlock> _readDiaryBlocks(Object? value) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map>()
        .map((entry) => DiaryBlock.fromJson(Map<String, dynamic>.from(entry)))
        .where((entry) => entry.type == 'text' || entry.imagePath.isNotEmpty)
        .toList();
  }

  static List<AttachmentImage> _readAttachmentImages(Object? value) {
    if (value is! List) {
      return const [];
    }

    return value
        .whereType<Map>()
        .map(
          (entry) =>
              AttachmentImage.fromJson(Map<String, dynamic>.from(entry)),
        )
        .where((entry) => entry.imagePath.isNotEmpty)
        .toList();
  }

  static List<DiaryBlock> _textOnlyLegacyBlocks(String text) {
    if (text.trim().isEmpty) {
      return const [];
    }
    return [
      DiaryBlock(
        id: 'legacy-text-${text.hashCode}',
        type: 'text',
        text: text,
        imagePath: '',
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
      ),
    ];
  }

  static List<AttachmentImage> _legacyAttachmentImages(List<String> images) {
    final now = DateTime.fromMillisecondsSinceEpoch(0);
    return images
        .map(
          (path) => AttachmentImage(
            id: 'legacy-attachment-${path.hashCode}',
            imagePath: path,
            createdAt: now,
          ),
        )
        .toList();
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

class DiaryBlock {
  const DiaryBlock({
    required this.id,
    required this.type,
    required this.text,
    required this.imagePath,
    required this.createdAt,
    this.thumbnailPath,
    this.imageWidth,
    this.imageHeight,
  });

  final String id;
  final String type;
  final String text;
  final String imagePath;
  final String? thumbnailPath;
  final double? imageWidth;
  final double? imageHeight;
  final DateTime createdAt;

  bool get isText => type == 'text';
  bool get isImage => type == 'image';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'text': text,
      'imagePath': imagePath,
      'createdAt': createdAt.toIso8601String(),
      if (thumbnailPath != null) 'thumbnailPath': thumbnailPath,
      if (imageWidth != null) 'imageWidth': imageWidth,
      if (imageHeight != null) 'imageHeight': imageHeight,
    };
  }

  factory DiaryBlock.fromJson(Map<String, dynamic> json) {
    final createdAt =
        DateTime.tryParse(json['createdAt'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
    final type = json['type'] as String? ?? 'text';
    return DiaryBlock(
      id:
          json['id'] as String? ??
          'diary-block-${createdAt.microsecondsSinceEpoch}',
      type: type == 'image' ? 'image' : 'text',
      text: json['text'] as String? ?? '',
      imagePath: json['imagePath'] as String? ?? '',
      createdAt: createdAt,
      thumbnailPath: json['thumbnailPath'] as String?,
      imageWidth: _readNullableDouble(json['imageWidth']),
      imageHeight: _readNullableDouble(json['imageHeight']),
    );
  }

  static double? _readNullableDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

class AttachmentImage {
  const AttachmentImage({
    required this.id,
    required this.imagePath,
    required this.createdAt,
    this.thumbnailPath,
  });

  final String id;
  final String imagePath;
  final String? thumbnailPath;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'imagePath': imagePath,
      'createdAt': createdAt.toIso8601String(),
      if (thumbnailPath != null) 'thumbnailPath': thumbnailPath,
    };
  }

  factory AttachmentImage.fromJson(Map<String, dynamic> json) {
    final createdAt =
        DateTime.tryParse(json['createdAt'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
    return AttachmentImage(
      id: json['id'] as String? ?? '',
      imagePath: json['imagePath'] as String? ?? '',
      createdAt: createdAt,
      thumbnailPath: json['thumbnailPath'] as String?,
    );
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
