import 'package:flutter/material.dart';
import 'package:pink_diary_calendar/config/app_info.dart';
import 'package:pink_diary_calendar/models/anniversary.dart';
import 'package:pink_diary_calendar/models/daily_record.dart';
import 'package:pink_diary_calendar/models/life_list.dart';
import 'package:pink_diary_calendar/pages/day_detail_page.dart';
import 'package:pink_diary_calendar/pages/expense_summary_page.dart';
import 'package:pink_diary_calendar/pages/life_list_page.dart';
import 'package:pink_diary_calendar/services/local_storage_service.dart';
import 'package:pink_diary_calendar/theme/app_colors.dart';
import 'package:pink_diary_calendar/theme/app_theme.dart';
import 'package:pink_diary_calendar/utils/anniversary_utils.dart';
import 'package:pink_diary_calendar/utils/calendar_utils.dart';
import 'package:pink_diary_calendar/utils/expense_summary_utils.dart';
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
  Map<String, DailyRecord> _dailyRecords = {};
  List<Anniversary> _anniversaries = [];
  List<LifeList> _lifeLists = [];
  List<LifeListCategory> _lifeListCategories = [];

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

  Future<void> _pickVisibleMonth() async {
    final pickedMonth = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MonthPickerSheet(visibleMonth: _visibleMonth),
    );

    if (!mounted || pickedMonth == null) {
      return;
    }

    setState(() {
      _visibleMonth = CalendarUtils.monthOnly(pickedMonth);
    });
  }

  Future<void> _loadCalendarMarkers() async {
    final dailyRecords = await _storageService.loadDailyRecords();
    final anniversaries = await _storageService.loadAnniversaries();
    final lifeLists = await _storageService.loadLifeLists();
    final lifeListCategories = await _storageService.loadLifeListCategories();
    if (!mounted) {
      return;
    }

    setState(() {
      _dailyRecords = dailyRecords;
      _anniversaries = anniversaries;
      _lifeLists = lifeLists;
      _lifeListCategories = lifeListCategories;
    });
  }

  _CalendarMarkerType _markerTypeFor(DateTime date) {
    final dateKey = CalendarUtils.formatDateKey(date);
    final today = CalendarUtils.dateOnly(DateTime.now());
    final normalizedDate = CalendarUtils.dateOnly(date);
    final record = _dailyRecords[dateKey];
    final hasRecord = record?.hasContent ?? false;

    if (hasRecord && normalizedDate.isBefore(today)) {
      return _CalendarMarkerType.pastRecord;
    }

    if (normalizedDate.isAfter(today) && _hasFutureArrangement(record)) {
      return _CalendarMarkerType.futurePlan;
    }

    final hasAnniversary = _anniversaries.any(
      (anniversary) => AnniversaryUtils.matchesCalendarDate(anniversary, date),
    );
    if (hasAnniversary) {
      return _CalendarMarkerType.anniversary;
    }

    if (hasRecord) {
      return _CalendarMarkerType.record;
    }

    return _CalendarMarkerType.none;
  }

  bool _hasFutureArrangement(DailyRecord? record) {
    if (record == null) {
      return false;
    }

    return record.plans.isNotEmpty || record.text.trim().isNotEmpty;
  }

  Future<void> _openDayDetail(CalendarDay day) async {
    await _openDateDetail(day.date);
  }

  Future<void> _openDateDetail(DateTime date) async {
    setState(() {
      _selectedDate = CalendarUtils.dateOnly(date);
      _visibleMonth = CalendarUtils.monthOnly(date);
    });

    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            DayDetailPage(date: date, storageService: _storageService),
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

  Future<void> _openLifeListPage() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LifeListPage(storageService: _storageService),
      ),
    );

    if (!mounted) {
      return;
    }

    await _loadCalendarMarkers();
  }

  Future<void> _openExpenseSummaryPage() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ExpenseSummaryPage(storageService: _storageService),
      ),
    );

    if (!mounted) {
      return;
    }

    await _loadCalendarMarkers();
  }

  _RecentPlan? _findRecentPlan() {
    final today = CalendarUtils.dateOnly(DateTime.now());
    final candidates = <_RecentPlan>[];

    for (final entry in _dailyRecords.entries) {
      final date = AnniversaryUtils.parseDateKey(entry.key);
      if (date == null || !date.isAfter(today)) {
        continue;
      }

      final record = entry.value;
      PlanEntry? firstPlan;
      for (final plan in record.plans) {
        if (plan.text.trim().isNotEmpty) {
          firstPlan = plan;
          break;
        }
      }

      if (firstPlan != null) {
        candidates.add(
          _RecentPlan(
            date: date,
            title: firstPlan.text.trim(),
            note: firstPlan.note.trim(),
          ),
        );
        continue;
      }

      final text = record.text.trim();
      if (text.isNotEmpty) {
        candidates.add(
          _RecentPlan(
            date: date,
            title: text.split('\n').first.trim(),
            note: '',
          ),
        );
      }
    }

    candidates.sort((first, second) => first.date.compareTo(second.date));
    return candidates.isEmpty ? null : candidates.first;
  }

  @override
  Widget build(BuildContext context) {
    final days = CalendarUtils.buildMonthGrid(_visibleMonth);
    final recentPlan = _findRecentPlan();
    final monthExpenseSummary = ExpenseSummaryUtils.currentMonthSummary(
      _dailyRecords,
    );
    final lifeListSubtitle = _lifeListSubtitle();
    final warmColors = Theme.of(context).extension<WarmThemeColors>();

    return WarmPageScaffold(
      child: ListView(
        key: const PageStorageKey('calendar-page'),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 128),
        children: [
          const WarmPageTitle(
            title: AppInfo.appName,
            subtitle: '记录过去，书写今天，安排未来',
            icon: Icons.calendar_month_rounded,
            trailing: LineDogDecoration(),
          ),
          const SizedBox(height: 18),
          WarmCard(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
            color:
                warmColors?.calendarCardBackground.withValues(alpha: 0.92) ??
                const Color(0xFFEAF5F8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.78)),
            child: Column(
              children: [
                _MonthSwitcher(
                  title: CalendarUtils.formatYearMonth(_visibleMonth),
                  onPrevious: _showPreviousMonth,
                  onNext: _showNextMonth,
                  onTitleTap: _pickVisibleMonth,
                ),
                const SizedBox(height: 14),
                _WeekdayRow(labels: _weekdayLabels),
                const SizedBox(height: 8),
                GridView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: days.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 18,
                    crossAxisSpacing: 6,
                    childAspectRatio: 1,
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
                      markerType: _markerTypeFor(day.date),
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
          _RecentPlanCard(
            plan: recentPlan,
            onTap: recentPlan == null
                ? null
                : () => _openDateDetail(recentPlan.date),
          ),
          const SizedBox(height: 12),
          _MonthExpenseHomeCard(
            summary: monthExpenseSummary,
            onTap: _openExpenseSummaryPage,
          ),
          const SizedBox(height: 12),
          _LifeListHomeCard(
            subtitle: lifeListSubtitle,
            onTap: _openLifeListPage,
          ),
        ],
      ),
    );
  }

  String _lifeListSubtitle() {
    final builtInCount = LifeListCategory.builtInCategories().length;
    if (_lifeListCategories.length > builtInCount) {
      return '${_lifeListCategories.length} 个清单分类正在使用';
    }

    if (_lifeLists.isEmpty) {
      return '购物、学习、旅行，都可以慢慢整理';
    }

    final unfinishedCount = _lifeLists.fold<int>(
      0,
      (count, list) => count + list.unfinishedCount,
    );
    if (unfinishedCount > 0) {
      return '还有 $unfinishedCount 个小事项待完成';
    }

    return '今天的清单都整理好啦';
  }
}

enum _CalendarMarkerType { none, pastRecord, futurePlan, anniversary, record }

class _RecentPlan {
  const _RecentPlan({
    required this.date,
    required this.title,
    required this.note,
  });

  final DateTime date;
  final String title;
  final String note;
}

class _RecentPlanCard extends StatelessWidget {
  const _RecentPlanCard({required this.plan, required this.onTap});

  final _RecentPlan? plan;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final currentPlan = plan;
    final warmColors = Theme.of(context).extension<WarmThemeColors>();

    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: WarmCard(
        color:
            warmColors?.planCardBackground.withValues(alpha: 0.88) ??
            const Color(0xFFEAF4F8).withValues(alpha: 0.76),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.82),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.event_note_rounded,
                color: warmColors?.primary ?? const Color(0xFF6F9FC4),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('最近计划', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 5),
                  if (currentPlan == null) ...[
                    Text(
                      '暂时还没有未来计划',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '想给未来的某一天留个安排吗？',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                    ),
                  ] else ...[
                    Text(
                      '${CalendarUtils.formatMonthDay(currentPlan.date)}：${currentPlan.title}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (currentPlan.note.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        currentPlan.note,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            if (currentPlan != null)
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.muted.withValues(alpha: 0.62),
              ),
          ],
        ),
      ),
    );
  }
}

class _MonthExpenseHomeCard extends StatelessWidget {
  const _MonthExpenseHomeCard({required this.summary, required this.onTap});

  final ExpenseSummary summary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final warmColors = Theme.of(context).extension<WarmThemeColors>();

    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: WarmCard(
        color:
            warmColors?.expenseCardBackground.withValues(alpha: 0.88) ??
            const Color(0xFFEDF7F0).withValues(alpha: 0.76),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.milk.withValues(alpha: 0.84),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.savings_outlined,
                color: warmColors?.secondary ?? const Color(0xFF7FA08A),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('本月小账', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 5),
                  if (summary.hasEntries) ...[
                    Text(
                      '支出 ${ExpenseSummaryUtils.formatMoney(summary.totalExpense)} · 收入 ${ExpenseSummaryUtils.formatMoney(summary.totalIncome)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '看看这个月的钱都去了哪里',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                    ),
                  ] else ...[
                    Text(
                      '还没有小账记录',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '在某一天记一笔，就能在这里回顾啦',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.muted.withValues(alpha: 0.62),
            ),
          ],
        ),
      ),
    );
  }
}

class _LifeListHomeCard extends StatelessWidget {
  const _LifeListHomeCard({required this.subtitle, required this.onTap});

  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final warmColors = Theme.of(context).extension<WarmThemeColors>();

    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: WarmCard(
        color:
            warmColors?.lifeListCardBackground.withValues(alpha: 0.9) ??
            const Color(0xFFF8F3E8).withValues(alpha: 0.78),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.milk.withValues(alpha: 0.84),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.checklist_rounded,
                color: warmColors?.accent ?? const Color(0xFFB59B67),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('生活清单', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.muted.withValues(alpha: 0.62),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthPickerSheet extends StatefulWidget {
  const _MonthPickerSheet({required this.visibleMonth});

  final DateTime visibleMonth;

  @override
  State<_MonthPickerSheet> createState() => _MonthPickerSheetState();
}

class _MonthPickerSheetState extends State<_MonthPickerSheet> {
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.visibleMonth.year;
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final warmColors = Theme.of(context).extension<WarmThemeColors>();

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
        decoration: BoxDecoration(
          color: warmColors?.card ?? AppColors.milk,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  _RoundIconButton(
                    icon: Icons.chevron_left_rounded,
                    tooltip: '上一年',
                    onPressed: () => setState(() => _selectedYear--),
                  ),
                  Expanded(
                    child: Text(
                      '$_selectedYear 年',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  _RoundIconButton(
                    icon: Icons.chevron_right_rounded,
                    tooltip: '下一年',
                    onPressed: () => setState(() => _selectedYear++),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 12,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.55,
                ),
                itemBuilder: (context, index) {
                  final month = index + 1;
                  final selected =
                      _selectedYear == widget.visibleMonth.year &&
                      month == widget.visibleMonth.month;
                  return InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => Navigator.of(
                      context,
                    ).pop(DateTime(_selectedYear, month)),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? (warmColors?.primarySoft ?? AppColors.cream)
                                  .withValues(alpha: 0.95)
                            : (warmColors?.card ?? AppColors.cream).withValues(
                                alpha: 0.72,
                              ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: selected
                              ? (warmColors?.primary ?? AppColors.ink)
                              : (warmColors?.primarySoft ?? AppColors.line)
                                    .withValues(alpha: 0.75),
                        ),
                      ),
                      child: Text(
                        '$month 月',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: AppColors.ink,
                              fontWeight: selected
                                  ? FontWeight.w900
                                  : FontWeight.w700,
                            ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthSwitcher extends StatelessWidget {
  const _MonthSwitcher({
    required this.title,
    required this.onPrevious,
    required this.onNext,
    required this.onTitleTap,
  });

  final String title;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onTitleTap;

  @override
  Widget build(BuildContext context) {
    final warmColors = Theme.of(context).extension<WarmThemeColors>();

    return Row(
      children: [
        _RoundIconButton(
          key: const ValueKey('calendar-previous-month'),
          icon: Icons.chevron_left_rounded,
          tooltip: '上个月',
          onPressed: onPrevious,
        ),
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: onTitleTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: warmColors?.textPrimary ?? AppColors.ink,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
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
    final warmColors = Theme.of(context).extension<WarmThemeColors>();

    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onPressed,
        radius: 26,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: (warmColors?.primarySoft ?? AppColors.cream).withValues(
              alpha: 0.82,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: warmColors?.primary ?? AppColors.ink,
            size: 28,
          ),
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
    final warmColors = Theme.of(context).extension<WarmThemeColors>();

    return Row(
      children: labels
          .map(
            (label) => Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: warmColors?.textSecondary ?? AppColors.muted,
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
    required this.markerType,
    required this.onTap,
    super.key,
  });

  final CalendarDay day;
  final bool isSelected;
  final _CalendarMarkerType markerType;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final warmColors = Theme.of(context).extension<WarmThemeColors>();
    final primary = warmColors?.primary ?? const Color(0xFF7FA3AF);
    final secondary = warmColors?.secondary ?? AppColors.lavenderDeep;
    final textPrimary = warmColors?.textPrimary ?? AppColors.ink;
    final textSecondary = warmColors?.textSecondary ?? AppColors.muted;
    final softBorder = warmColors?.primarySoft ?? AppColors.line;
    final textColor = switch ((isSelected, day.isCurrentMonth)) {
      (true, _) => textPrimary,
      (false, true) => textPrimary,
      (false, false) => textSecondary.withValues(alpha: 0.5),
    };
    final backgroundColor = switch ((isSelected, day.isCurrentMonth)) {
      (true, _) => primary.withValues(alpha: 0.78),
      (false, true) => Colors.white.withValues(alpha: 0.72),
      (false, false) => softBorder.withValues(alpha: 0.34),
    };
    final borderColor = isSelected
        ? primary
        : day.isToday
        ? secondary.withValues(alpha: 0.8)
        : softBorder.withValues(alpha: 0.82);

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
              Align(
                alignment: markerType == _CalendarMarkerType.none
                    ? Alignment.center
                    : const Alignment(0, -0.34),
                child: Text(
                  '${day.date.day}',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: isSelected || day.isToday
                        ? FontWeight.w800
                        : FontWeight.w600,
                  ),
                ),
              ),
              if (day.isToday && markerType == _CalendarMarkerType.none)
                Positioned(
                  bottom: 7,
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.ink : secondary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              _CalendarMarker(markerType: markerType, isSelected: isSelected),
            ],
          ),
        ),
      ),
    );
  }
}

class _CalendarMarker extends StatelessWidget {
  const _CalendarMarker({required this.markerType, required this.isSelected});

  final _CalendarMarkerType markerType;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    if (markerType == _CalendarMarkerType.none) {
      return const SizedBox.shrink();
    }

    final warmColors = Theme.of(context).extension<WarmThemeColors>();
    final primary = warmColors?.primary ?? const Color(0xFF7FA3AF);
    final secondary = warmColors?.secondary ?? AppColors.lavenderDeep;
    final icon = switch (markerType) {
      _CalendarMarkerType.pastRecord => Icons.check_rounded,
      _CalendarMarkerType.futurePlan => Icons.favorite_rounded,
      _CalendarMarkerType.anniversary => Icons.auto_awesome_rounded,
      _CalendarMarkerType.record => Icons.favorite_rounded,
      _CalendarMarkerType.none => Icons.circle,
    };
    final color = switch (markerType) {
      _CalendarMarkerType.pastRecord => const Color(0xFF5FA86F),
      _CalendarMarkerType.futurePlan => primary,
      _CalendarMarkerType.anniversary => warmColors?.accent ?? secondary,
      _CalendarMarkerType.record => primary,
      _CalendarMarkerType.none => AppColors.muted,
    };

    return Positioned(
      left: 0,
      right: 0,
      bottom: 3,
      child: Icon(
        icon,
        size: switch (markerType) {
          _CalendarMarkerType.pastRecord => 13,
          _CalendarMarkerType.anniversary => 9,
          _ => 10,
        },
        color: color.withValues(alpha: isSelected ? 0.96 : 0.86),
      ),
    );
  }
}
