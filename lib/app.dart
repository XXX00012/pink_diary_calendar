import 'package:flutter/material.dart';
import 'package:pink_diary_calendar/pages/home_shell_page.dart';
import 'package:pink_diary_calendar/services/notification_service.dart';
import 'package:pink_diary_calendar/theme/app_theme.dart';
import 'package:pink_diary_calendar/theme/theme_controller.dart';

class WarmPeachCalendarApp extends StatefulWidget {
  const WarmPeachCalendarApp({super.key});

  @override
  State<WarmPeachCalendarApp> createState() => _WarmPeachCalendarAppState();
}

class _WarmPeachCalendarAppState extends State<WarmPeachCalendarApp> {
  final AppThemeController _themeController = AppThemeController.instance;

  @override
  void initState() {
    super.initState();
    _themeController.loadTheme();
    NotificationService.instance
        .initialize()
        .then((_) {
          return NotificationService.instance
              .rescheduleAnniversaryNotifications();
        })
        .catchError((Object error, StackTrace stackTrace) {
          debugPrint('Startup notification sync failed: $error');
          debugPrintStack(stackTrace: stackTrace);
          return false;
        });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeController,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: '暖桃日记',
          theme: AppTheme.light(_themeController.themeKey),
          home: const HomeShellPage(),
        );
      },
    );
  }
}
