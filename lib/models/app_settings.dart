class AppSettings {
  const AppSettings({
    required this.privacyLockEnabled,
    required this.passwordHint,
    required this.reminderEnabled,
    required this.dailyReminderTime,
    required this.anniversaryNotificationEnabled,
    required this.anniversaryReminderTime,
    required this.notificationPermissionGranted,
    required this.themeKey,
    required this.updatedAt,
  });

  static AppSettings defaults() {
    return AppSettings(
      privacyLockEnabled: false,
      passwordHint: '',
      reminderEnabled: false,
      dailyReminderTime: '09:00',
      anniversaryNotificationEnabled: false,
      anniversaryReminderTime: '09:00',
      notificationPermissionGranted: false,
      themeKey: 'minimalWhite',
      updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  final bool privacyLockEnabled;
  final String passwordHint;
  // Kept for compatibility with older local settings. UI now treats these as
  // anniversary notification preferences, not diary reminders.
  final bool reminderEnabled;
  final String dailyReminderTime;
  final bool anniversaryNotificationEnabled;
  final String anniversaryReminderTime;
  final bool notificationPermissionGranted;
  final String themeKey;
  final DateTime updatedAt;

  AppSettings copyWith({
    bool? privacyLockEnabled,
    String? passwordHint,
    bool? reminderEnabled,
    String? dailyReminderTime,
    bool? anniversaryNotificationEnabled,
    String? anniversaryReminderTime,
    bool? notificationPermissionGranted,
    String? themeKey,
    DateTime? updatedAt,
  }) {
    final nextAnniversaryEnabled =
        anniversaryNotificationEnabled ??
        reminderEnabled ??
        this.anniversaryNotificationEnabled;
    final nextAnniversaryTime =
        anniversaryReminderTime ??
        dailyReminderTime ??
        this.anniversaryReminderTime;

    return AppSettings(
      privacyLockEnabled: privacyLockEnabled ?? this.privacyLockEnabled,
      passwordHint: passwordHint ?? this.passwordHint,
      reminderEnabled: nextAnniversaryEnabled,
      dailyReminderTime: nextAnniversaryTime,
      anniversaryNotificationEnabled: nextAnniversaryEnabled,
      anniversaryReminderTime: nextAnniversaryTime,
      notificationPermissionGranted:
          notificationPermissionGranted ?? this.notificationPermissionGranted,
      themeKey: themeKey ?? this.themeKey,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'privacyLockEnabled': privacyLockEnabled,
      'passwordHint': passwordHint,
      'reminderEnabled': anniversaryNotificationEnabled,
      'dailyReminderTime': anniversaryReminderTime,
      'anniversaryNotificationEnabled': anniversaryNotificationEnabled,
      'anniversaryReminderTime': anniversaryReminderTime,
      'notificationPermissionGranted': notificationPermissionGranted,
      'themeKey': themeKey,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final defaults = AppSettings.defaults();
    final anniversaryNotificationEnabled =
        json['anniversaryNotificationEnabled'] as bool? ??
        json['reminderEnabled'] as bool? ??
        defaults.anniversaryNotificationEnabled;
    final anniversaryReminderTime =
        json['anniversaryReminderTime'] as String? ??
        json['dailyReminderTime'] as String? ??
        defaults.anniversaryReminderTime;

    return AppSettings(
      privacyLockEnabled:
          json['privacyLockEnabled'] as bool? ?? defaults.privacyLockEnabled,
      passwordHint: json['passwordHint'] as String? ?? defaults.passwordHint,
      reminderEnabled: anniversaryNotificationEnabled,
      dailyReminderTime: anniversaryReminderTime,
      anniversaryNotificationEnabled: anniversaryNotificationEnabled,
      anniversaryReminderTime: anniversaryReminderTime,
      notificationPermissionGranted:
          json['notificationPermissionGranted'] as bool? ??
          defaults.notificationPermissionGranted,
      themeKey: json['themeKey'] as String? ?? defaults.themeKey,
      updatedAt:
          DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          defaults.updatedAt,
    );
  }
}
