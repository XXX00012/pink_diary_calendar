class AppSettings {
  const AppSettings({
    required this.privacyLockEnabled,
    required this.passwordHint,
    required this.reminderEnabled,
    required this.dailyReminderTime,
    required this.themeKey,
    required this.updatedAt,
  });

  static AppSettings defaults() {
    return AppSettings(
      privacyLockEnabled: false,
      passwordHint: '',
      reminderEnabled: false,
      dailyReminderTime: '21:30',
      themeKey: 'pink',
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  final bool privacyLockEnabled;
  final String passwordHint;
  final bool reminderEnabled;
  final String dailyReminderTime;
  final String themeKey;
  final DateTime updatedAt;

  AppSettings copyWith({
    bool? privacyLockEnabled,
    String? passwordHint,
    bool? reminderEnabled,
    String? dailyReminderTime,
    String? themeKey,
    DateTime? updatedAt,
  }) {
    return AppSettings(
      privacyLockEnabled: privacyLockEnabled ?? this.privacyLockEnabled,
      passwordHint: passwordHint ?? this.passwordHint,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      dailyReminderTime: dailyReminderTime ?? this.dailyReminderTime,
      themeKey: themeKey ?? this.themeKey,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'privacyLockEnabled': privacyLockEnabled,
      'passwordHint': passwordHint,
      'reminderEnabled': reminderEnabled,
      'dailyReminderTime': dailyReminderTime,
      'themeKey': themeKey,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final defaults = AppSettings.defaults();
    return AppSettings(
      privacyLockEnabled:
          json['privacyLockEnabled'] as bool? ?? defaults.privacyLockEnabled,
      passwordHint: json['passwordHint'] as String? ?? defaults.passwordHint,
      reminderEnabled:
          json['reminderEnabled'] as bool? ?? defaults.reminderEnabled,
      dailyReminderTime:
          json['dailyReminderTime'] as String? ?? defaults.dailyReminderTime,
      themeKey: json['themeKey'] as String? ?? defaults.themeKey,
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          defaults.updatedAt,
    );
  }
}
