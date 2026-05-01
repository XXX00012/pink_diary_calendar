import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:pink_diary_calendar/models/anniversary.dart';
import 'package:pink_diary_calendar/models/app_settings.dart';
import 'package:pink_diary_calendar/services/local_storage_service.dart';
import 'package:pink_diary_calendar/utils/anniversary_utils.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const String _anniversaryChannelId = 'anniversary_reminders';
  static const String _notificationIcon = 'notification_icon';
  static const int _testNotificationId = 991001;

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  Future<bool>? _initializeFuture;

  Future<bool> initialize() async {
    if (_initialized) {
      return true;
    }
    _initializeFuture ??= _doInitialize();
    return _initializeFuture!;
  }

  Future<bool> _doInitialize() async {
    try {
      timezone_data.initializeTimeZones();
      await _configureLocalTimezone();

      const androidSettings = AndroidInitializationSettings(_notificationIcon);
      const initializationSettings = InitializationSettings(
        android: androidSettings,
      );

      await _notifications.initialize(initializationSettings);

      const androidChannel = AndroidNotificationChannel(
        _anniversaryChannelId,
        '纪念日提醒',
        description: '生日、纪念日和重要日期提醒',
        importance: Importance.high,
      );
      await _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(androidChannel);

      _initialized = true;
      return true;
    } catch (error, stackTrace) {
      _initializeFuture = null;
      debugPrint('NotificationService initialize failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> requestPermission() async {
    try {
      final initialized = await initialize();
      if (!initialized) {
        return false;
      }

      final androidGranted = await _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
      if (androidGranted != null) {
        return androidGranted;
      }

      return false;
    } catch (error, stackTrace) {
      debugPrint('NotificationService requestPermission failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> areNotificationsEnabled() async {
    try {
      final initialized = await initialize();
      if (!initialized) {
        return false;
      }

      final androidEnabled = await _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.areNotificationsEnabled();
      if (androidEnabled != null) {
        return androidEnabled;
      }

      return false;
    } catch (error, stackTrace) {
      debugPrint('NotificationService areNotificationsEnabled failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> cancelAllAnniversaryNotifications() async {
    try {
      final initialized = await initialize();
      if (!initialized) {
        return false;
      }
      await _notifications.cancelAll();
      return true;
    } catch (error, stackTrace) {
      debugPrint(
        'NotificationService cancelAllAnniversaryNotifications failed: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> rescheduleAnniversaryNotifications({
    LocalStorageService storageService = const LocalStorageService(),
  }) async {
    try {
      final settings = await storageService.loadAppSettings();
      final anniversaries = await storageService.loadAnniversaries();
      final scheduled = await scheduleAnniversaryNotifications(
        anniversaries,
        settings,
      );
      if (!scheduled && settings.anniversaryNotificationEnabled) {
        await storageService.saveAppSettings(
          settings.copyWith(
            anniversaryNotificationEnabled: false,
            updatedAt: DateTime.now(),
          ),
        );
      }
      return scheduled;
    } catch (error, stackTrace) {
      debugPrint(
        'NotificationService rescheduleAnniversaryNotifications failed: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> scheduleAnniversaryNotifications(
    List<Anniversary> anniversaries,
    AppSettings settings,
  ) async {
    try {
      final initialized = await initialize();
      if (!initialized) {
        return false;
      }
      final cancelled = await cancelAllAnniversaryNotifications();
      if (!cancelled) {
        return false;
      }

      if (!settings.anniversaryNotificationEnabled ||
          !settings.notificationPermissionGranted) {
        return true;
      }

      final permissionGranted = await areNotificationsEnabled();
      if (!permissionGranted) {
        return false;
      }

      final reminderTime = _parseReminderTime(settings.anniversaryReminderTime);
      final now = DateTime.now();

      for (final anniversary in anniversaries) {
        if (anniversary.remindBeforeDays < 0) {
          continue;
        }

        final eventDate = _nextEventDateForScheduling(
          anniversary,
          reminderTime.hour,
          reminderTime.minute,
          now,
        );
        if (eventDate == null) {
          continue;
        }

        final scheduleDate = DateTime(
          eventDate.year,
          eventDate.month,
          eventDate.day,
          reminderTime.hour,
          reminderTime.minute,
        ).subtract(Duration(days: anniversary.remindBeforeDays));

        if (!scheduleDate.isAfter(now)) {
          continue;
        }

        final content = _notificationContent(anniversary);
        await _notifications.zonedSchedule(
          _stableNotificationId(anniversary, eventDate.year),
          content.title,
          content.body,
          timezone.TZDateTime.from(scheduleDate, timezone.local),
          _notificationDetails(),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
      return true;
    } catch (error, stackTrace) {
      debugPrint(
        'NotificationService scheduleAnniversaryNotifications failed: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  Future<bool> scheduleTestNotification() async {
    try {
      final initialized = await initialize();
      if (!initialized) {
        return false;
      }
      await _notifications.show(
        _testNotificationId,
        '暖桃日记',
        '通知功能已经开启，重要日子不会被忘记啦',
        _notificationDetails(),
      );
      return true;
    } catch (error, stackTrace) {
      debugPrint('NotificationService scheduleTestNotification failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      return false;
    }
  }

  Future<void> _configureLocalTimezone() async {
    try {
      final localTimezone = await FlutterTimezone.getLocalTimezone();
      timezone.setLocalLocation(timezone.getLocation(localTimezone));
    } catch (error, stackTrace) {
      debugPrint('NotificationService configure timezone failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      try {
        timezone.setLocalLocation(timezone.getLocation('Asia/Shanghai'));
      } catch (_) {
        timezone.setLocalLocation(timezone.local);
      }
    }
  }

  NotificationDetails _notificationDetails() {
    const androidDetails = AndroidNotificationDetails(
      _anniversaryChannelId,
      '纪念日提醒',
      channelDescription: '生日、纪念日和重要日期提醒',
      importance: Importance.high,
      priority: Priority.high,
      icon: _notificationIcon,
    );
    return const NotificationDetails(android: androidDetails);
  }

  _ReminderTime _parseReminderTime(String value) {
    final parts = value.split(':');
    final hour = int.tryParse(parts.first) ?? 9;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    return _ReminderTime(
      hour.clamp(0, 23).toInt(),
      minute.clamp(0, 59).toInt(),
    );
  }

  DateTime? _nextEventDateForScheduling(
    Anniversary anniversary,
    int hour,
    int minute,
    DateTime now,
  ) {
    final baseDate = AnniversaryUtils.parseDateKey(anniversary.date);
    if (baseDate == null) {
      return null;
    }

    if (!anniversary.repeatYearly) {
      final scheduleDate = DateTime(
        baseDate.year,
        baseDate.month,
        baseDate.day,
        hour,
        minute,
      ).subtract(Duration(days: anniversary.remindBeforeDays));
      return scheduleDate.isAfter(now) ? baseDate : null;
    }

    var eventDate = _safeAnnualDate(now.year, baseDate.month, baseDate.day);
    var scheduleDate = DateTime(
      eventDate.year,
      eventDate.month,
      eventDate.day,
      hour,
      minute,
    ).subtract(Duration(days: anniversary.remindBeforeDays));

    if (!scheduleDate.isAfter(now)) {
      eventDate = _safeAnnualDate(now.year + 1, baseDate.month, baseDate.day);
    }

    return eventDate;
  }

  DateTime _safeAnnualDate(int year, int month, int day) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, day.clamp(1, lastDay).toInt());
  }

  _NotificationContent _notificationContent(Anniversary anniversary) {
    final title = anniversary.title.trim().isEmpty
        ? '这个重要日子'
        : anniversary.title.trim();
    final days = anniversary.remindBeforeDays;

    if (days == 0) {
      return _NotificationContent('今天是重要日子', '今天是「$title」');
    }

    if (days == 1) {
      return _NotificationContent('重要日子提醒', '明天是「$title」，别忘啦');
    }

    return _NotificationContent('重要日子快到啦', '距离「$title」还有 $days 天');
  }

  int _stableNotificationId(Anniversary anniversary, int eventYear) {
    final source =
        '${anniversary.id}-${anniversary.remindBeforeDays}-$eventYear';
    var hash = 17;
    for (final codeUnit in source.codeUnits) {
      hash = (hash * 37 + codeUnit) & 0x7fffffff;
    }
    return 10000 + (hash % 1900000000);
  }
}

class _ReminderTime {
  const _ReminderTime(this.hour, this.minute);

  final int hour;
  final int minute;
}

class _NotificationContent {
  const _NotificationContent(this.title, this.body);

  final String title;
  final String body;
}
