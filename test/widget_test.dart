import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pink_diary_calendar/app.dart';
import 'package:pink_diary_calendar/utils/calendar_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('bottom navigation switches between the three pages', (
    tester,
  ) async {
    await tester.pumpWidget(const WarmPeachCalendarApp());

    expect(find.text('拾光日记'), findsOneWidget);
    expect(find.byKey(const ValueKey('nav-calendar')), findsOneWidget);
    expect(find.byKey(const ValueKey('nav-anniversary')), findsOneWidget);
    expect(find.byKey(const ValueKey('nav-profile')), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );

    await tester.tap(find.byKey(const ValueKey('nav-anniversary')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );
    expect(find.text('还没有重要日子，添加一个想被记住的瞬间吧'), findsOneWidget);
    expect(find.byKey(const ValueKey('add-anniversary-button')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nav-profile')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      2,
    );
    expect(find.text('小桃子'), findsOneWidget);
    expect(find.text('今天也要好好生活'), findsOneWidget);
    expect(find.text('主题装扮'), findsOneWidget);
    expect(find.text('关于拾光日记'), findsOneWidget);
  });

  testWidgets('calendar opens daily record page and reloads saved text', (
    tester,
  ) async {
    await tester.pumpWidget(const WarmPeachCalendarApp());
    await tester.pumpAndSettle();

    final now = DateTime.now();
    final thisMonth = CalendarUtils.monthOnly(now);
    final nextMonth = CalendarUtils.nextMonth(thisMonth);

    expect(find.text(CalendarUtils.formatYearMonth(thisMonth)), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('calendar-next-month')));
    await tester.pumpAndSettle();
    expect(find.text(CalendarUtils.formatYearMonth(nextMonth)), findsOneWidget);

    final detailDate = DateTime(nextMonth.year, nextMonth.month, 15);
    final dayKey = ValueKey(
      'calendar-day-${detailDate.year}-${detailDate.month}-${detailDate.day}',
    );
    await tester.tap(find.byKey(dayKey));
    await tester.pumpAndSettle();

    expect(
      find.text(CalendarUtils.formatMonthDayWithWeekday(detailDate)),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('daily-record-input')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey('daily-record-input')),
      '今天想把温柔的小事留下来。',
    );
    await tester.tap(find.byKey(const ValueKey('save-daily-record-button')));
    await tester.pumpAndSettle();

    expect(find.text('这一天已经被好好收藏啦'), findsOneWidget);

    await tester.tap(find.byKey(dayKey));
    await tester.pumpAndSettle();
    expect(
      find.text('今天想把温柔的小事留下来。'),
      findsOneWidget,
    );
  });
}
