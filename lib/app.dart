import 'package:flutter/material.dart';
import 'package:pink_diary_calendar/pages/home_shell_page.dart';
import 'package:pink_diary_calendar/theme/app_theme.dart';

class WarmPeachCalendarApp extends StatelessWidget {
  const WarmPeachCalendarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '暖桃日历',
      theme: AppTheme.light(),
      home: const HomeShellPage(),
    );
  }
}
