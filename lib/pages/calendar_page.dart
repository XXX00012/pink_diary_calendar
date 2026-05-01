import 'package:flutter/material.dart';
import 'package:pink_diary_calendar/models/anniversary.dart';
import 'package:pink_diary_calendar/pages/day_detail_page.dart';
import 'package:pink_diary_calendar/services/local_storage_service.dart';
import 'package:pink_diary_calendar/theme/app_colors.dart';
import 'package:pink_diary_calendar/utils/anniversary_utils.dart';
import 'package:pink_diary_calendar/utils/calendar_utils.dart';
import 'package:pink_diary_calendar/widgets/warm_card.dart';
import 'package:pink_diary_calendar/widgets/warm_page_scaffold.dart';
import 'package:pink_diary_calendar/widgets/warm_page_title.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key, this.refreshToken = 0});

  final int refreshToken;

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  static const _weekdayLabels = ['日', '一', '二', '三', '四', '五', '六'];

  final LocalStorageService _storageService = const LocalStorageService();

  late DateTime _visibleMonth;
  late DateTime _selectedDate;
  Set<String> _recordedDateKeys = {};
  List<Anniversary> _anniversaries = [];

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _visibleMonth = CalendarUtils.monthOnly(today);
    _selectedDate = CalendarUtils.dateOnly(today);
    _loadCalendarMarkers();
  }

  @override
  void didUpdateWidget(covariant CalendarPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _loadCalendarMarkers();
    }
  }

  void _showPreviousMonth() {
    setState(() {
      _visibleMonth = CalendarUtils.previousMonth(_visibleMonth);
    });
  }

  void _showNextMonth() {
    setState(() {
      _visibleMonth = CalendarUtils.nextMonth(_visibleMonth);
    });
  }

  Future<void> _loadCalendarMarkers() async {
    final recordedDateKeys = await _storageService.loadRecordedDateKeys();
    final anniversaries = await _storageService.loadAnniversaries();
    if (!mounted) {
      return;
    }

    setState(() {
      _recordedDateKeys = recordedDateKeys;
      _anniversaries = anniversaries;
    });
  }

  bool _hasCalendarMarker(DateTime date) {
    final dateKey = CalendarUtils.formatDateKey(date);
    if (_recordedDateKeys.contains(dateKey)) {
      return true;
    }

    return _anniversaries.any(
      (anniversary) => AnniversaryUtils.matchesCalendarDate(anniversary, date),
    );
  }

  Future<void> _openDayDetail(CalendarDay day) async {
    setState(() {
      _selectedDate = CalendarUtils.dateOnly(day.date);
      _visibleMonth = CalendarUtils.monthOnly(day.date);
    });

    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            DayDetailPage(date: day.date, storageService: _storageService),
      ),
    );

    if (!mounted) {
      return;
    }

    await _loadCalendarMarkers();
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('这一天已经被好好收藏啦')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = CalendarUtils.buildMonthGrid(_visibleMonth);

    return WarmPageScaffold(
      child: ListView(
        key: const PageStorageKey('calendar-page'),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
        children: [
          const WarmPageTitle(
            title: '暖桃日历',
            subtitle: '记录过去，书写今天，安排未来',
            icon: Icons.calendar_month_rounded,
          ),
          const SizedBox(height: 18),
          WarmCard(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            child: Column(
              children: [
                _MonthSwitcher(
                  title: CalendarUtils.formatYearMonth(_visibleMonth),
                  onPrevious: _showPreviousMonth,
                  onNext: _showNextMonth,
                ),
                const SizedBox(height: 18),
                _WeekdayRow(labels: _weekdayLabels),
                const SizedBox(height: 10),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: days.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                    childAspectRatio: 0.86,
                  ),
                  itemBuilder: (context, index) {
                    final day = days[index];
                    return _CalendarDayCell(
                      key: ValueKey(
                        'calendar-day-${day.date.year}-${day.date.month}-${day.date.day}',
                      ),
                      day: day,
                      isSelected: CalendarUtils.isSameDay(
                        day.date,
                        _selectedDate,
                      ),
                      hasRecord:
                          _recordedDateKeys.contains(
                            CalendarUtils.formatDateKey(day.date),
                          ) ||
                          _hasCalendarMarker(day.date),
                      onTap: () {
                        _openDayDetail(day);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          WarmCard(
            color: AppColors.blush.withValues(alpha: 0.74),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.82),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.edit_calendar_rounded,
                    color: AppColors.roseDeep,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '选中的日子',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CalendarUtils.formatFullDate(_selectedDate),
                        key: const ValueKey('selected-date-label'),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthSwitcher extends StatelessWidget {
  const _MonthSwitcher({
    required this.title,
    required this.onPrevious,
    required this.onNext,
  });

  final String title;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundIconButton(
          key: const ValueKey('calendar-previous-month'),
          icon: Icons.chevron_left_rounded,
          tooltip: '上个月',
          onPressed: onPrevious,
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        _RoundIconButton(
          key: const ValueKey('calendar-next-month'),
          icon: Icons.chevron_right_rounded,
          tooltip: '下个月',
          onPressed: onNext,
        ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onPressed,
        radius: 26,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.blush.withValues(alpha: 0.82),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.roseDeep, size: 28),
        ),
      ),
    );
  }
}

class _WeekdayRow extends StatelessWidget {
  const _WeekdayRow({required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: labels
          .map(
            (label) => Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _CalendarDayCell extends StatelessWidget {
  const _CalendarDayCell({
    required this.day,
    required this.isSelected,
    required this.hasRecord,
    required this.onTap,
    super.key,
  });

  final CalendarDay day;
  final bool isSelected;
  final bool hasRecord;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textColor = switch ((isSelected, day.isCurrentMonth)) {
      (true, _) => Colors.white,
      (false, true) => AppColors.ink,
      (false, false) => AppColors.muted.withValues(alpha: 0.48),
    };
    final backgroundColor = switch ((isSelected, day.isCurrentMonth)) {
      (true, _) => AppColors.roseDeep,
      (false, true) => AppColors.milk.withValues(alpha: 0.72),
      (false, false) => AppColors.blush.withValues(alpha: 0.34),
    };
    final borderColor = isSelected
        ? AppColors.roseDeep
        : day.isToday
        ? AppColors.lavenderDeep.withValues(alpha: 0.8)
        : AppColors.line.withValues(alpha: 0.7);

    return Semantics(
      button: true,
      selected: isSelected,
      label: CalendarUtils.formatFullDate(day.date),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: borderColor,
              width: day.isToday || isSelected ? 1.4 : 1,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                '${day.date.day}',
                style: TextStyle(
                  color: textColor,
                  fontSize: 15,
                  fontWeight: isSelected || day.isToday
                      ? FontWeight.w800
                      : FontWeight.w600,
                ),
              ),
              if (day.isToday)
                Positioned(
                  bottom: 7,
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : AppColors.lavenderDeep,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              if (hasRecord)
                Positioned(
                  top: 6,
                  right: 7,
                  child: Icon(
                    Icons.favorite_rounded,
                    size: 9,
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.92)
                        : AppColors.roseDeep.withValues(alpha: 0.72),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
