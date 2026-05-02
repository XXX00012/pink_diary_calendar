import 'package:flutter/material.dart';
import 'package:pink_diary_calendar/pages/legal_consent_page.dart';
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
          home: const LegalGatePage(),
        );
      },
    );
  }
}
