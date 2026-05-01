import 'package:flutter/material.dart';
import 'package:pink_diary_calendar/pages/anniversary_page.dart';
import 'package:pink_diary_calendar/pages/calendar_page.dart';
import 'package:pink_diary_calendar/pages/profile_page.dart';
import 'package:pink_diary_calendar/theme/app_colors.dart';

class HomeShellPage extends StatefulWidget {
  const HomeShellPage({super.key});

  @override
  State<HomeShellPage> createState() => _HomeShellPageState();
}

class _HomeShellPageState extends State<HomeShellPage> {
  int _selectedIndex = 0;
  int _calendarRefreshToken = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          CalendarPage(refreshToken: _calendarRefreshToken),
          const AnniversaryPage(),
          const ProfilePage(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: AppColors.rose.withValues(alpha: 0.18),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: NavigationBar(
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) {
                setState(() {
                  _selectedIndex = index;
                  if (index == 0) {
                    _calendarRefreshToken++;
                  }
                });
              },
              destinations: const [
                NavigationDestination(
                  key: ValueKey('nav-calendar'),
                  icon: Icon(Icons.calendar_month_outlined),
                  selectedIcon: Icon(Icons.calendar_month_rounded),
                  label: '日历',
                ),
                NavigationDestination(
                  key: ValueKey('nav-anniversary'),
                  icon: Icon(Icons.favorite_border_rounded),
                  selectedIcon: Icon(Icons.favorite_rounded),
                  label: '纪念日',
                ),
                NavigationDestination(
                  key: ValueKey('nav-profile'),
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: '我的',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
