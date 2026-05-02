import 'package:flutter/material.dart';
import 'package:pink_diary_calendar/models/daily_record.dart';
import 'package:pink_diary_calendar/pages/day_detail_page.dart';
import 'package:pink_diary_calendar/services/local_storage_service.dart';
import 'package:pink_diary_calendar/theme/app_colors.dart';
import 'package:pink_diary_calendar/utils/calendar_utils.dart';
import 'package:pink_diary_calendar/utils/expense_summary_utils.dart';
import 'package:pink_diary_calendar/widgets/warm_card.dart';
import 'package:pink_diary_calendar/widgets/warm_page_scaffold.dart';

enum _ExpenseRangeType { last7Days, last30Days, thisMonth, lastMonth, custom }

class ExpenseSummaryPage extends StatefulWidget {
  const ExpenseSummaryPage({
    this.storageService = const LocalStorageService(),
    super.key,
  });

  final LocalStorageService storageService;

  @override
  State<ExpenseSummaryPage> createState() => _ExpenseSummaryPageState();
}

class _ExpenseSummaryPageState extends State<ExpenseSummaryPage> {
  Map<String, DailyRecord> _records = {};
  _ExpenseRangeType _rangeType = _ExpenseRangeType.thisMonth;
  ExpenseDateRange? _customRange;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final records = await widget.storageService.loadDailyRecords();
    if (!mounted) {
      return;
    }

    setState(() {
      _records = records;
      _isLoading = false;
    });
  }

  ExpenseDateRange get _activeRange {
    final today = CalendarUtils.dateOnly(DateTime.now());
    return switch (_rangeType) {
      _ExpenseRangeType.last7Days => ExpenseDateRange(
        start: today.subtract(const Duration(days: 6)),
        end: today,
      ),
      _ExpenseRangeType.last30Days => ExpenseDateRange(
        start: today.subtract(const Duration(days: 29)),
        end: today,
      ),
      _ExpenseRangeType.thisMonth => ExpenseSummaryUtils.monthRange(today),
      _ExpenseRangeType.lastMonth => ExpenseSummaryUtils.monthRange(
        DateTime(today.year, today.month - 1),
      ),
      _ExpenseRangeType.custom =>
        _customRange ?? ExpenseSummaryUtils.monthRange(today),
    };
  }

  String get _rangeTitle {
    final range = _activeRange;
    return switch (_rangeType) {
      _ExpenseRangeType.last7Days => '近 7 天小账',
      _ExpenseRangeType.last30Days => '近 30 天小账',
      _ExpenseRangeType.thisMonth =>
        '${range.start.year} 年 ${range.start.month} 月小账',
      _ExpenseRangeType.lastMonth =>
        '${range.start.year} 年 ${range.start.month} 月小账',
      _ExpenseRangeType.custom => ExpenseSummaryUtils.formatCompactRange(range),
    };
  }

  Future<void> _selectRange(_ExpenseRangeType type) async {
    if (type == _ExpenseRangeType.custom) {
      await _pickCustomRange();
      return;
    }

    setState(() => _rangeType = type);
  }

  Future<void> _pickCustomRange() async {
    final today = CalendarUtils.dateOnly(DateTime.now());
    final initialRange =
        _customRange ??
        ExpenseDateRange(
          start: today.subtract(const Duration(days: 6)),
          end: today,
        );

    final pickedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(today.year + 5, 12, 31),
      initialDateRange: DateTimeRange(
        start: initialRange.start,
        end: initialRange.end,
      ),
      helpText: '选择小账时间范围',
      cancelText: '取消',
      confirmText: '确定',
      saveText: '确定',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: AppColors.roseDeep,
              surface: AppColors.milk,
            ),
          ),
          child: child!,
        );
      },
    );

    if (!mounted || pickedRange == null) {
      return;
    }

    final start = CalendarUtils.dateOnly(pickedRange.start);
    final end = CalendarUtils.dateOnly(pickedRange.end);
    if (start.isAfter(end)) {
      _showSnackBar('请选择正确的日期范围');
      return;
    }

    setState(() {
      _rangeType = _ExpenseRangeType.custom;
      _customRange = ExpenseDateRange(start: start, end: end);
    });
  }

  Future<void> _openDayDetail(DateTime date) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            DayDetailPage(date: date, storageService: widget.storageService),
      ),
    );

    if (!mounted) {
      return;
    }
    await _loadRecords();
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final range = _activeRange;
    final result = ExpenseSummaryUtils.summarize(
      _records,
      start: range.start,
      end: range.end,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: WarmPageScaffold(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
          children: [
            _ExpenseHeader(onBack: () => Navigator.of(context).maybePop()),
            const SizedBox(height: 18),
            _RangeSelector(selectedType: _rangeType, onSelected: _selectRange),
            const SizedBox(height: 14),
            _SummaryCard(
              title: _rangeTitle,
              summary: result.summary,
              isLoading: _isLoading,
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const _LoadingCard()
            else if (result.groups.isEmpty)
              const _EmptyExpenseCard()
            else
              _ExpenseGroupList(
                groups: result.groups,
                onOpenDate: _openDayDetail,
              ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseHeader extends StatelessWidget {
  const _ExpenseHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Tooltip(
          message: '返回',
          child: InkResponse(
            onTap: onBack,
            radius: 28,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.milk.withValues(alpha: 0.9),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.roseDeep,
                size: 20,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('小账本', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 5),
              Text(
                '轻轻回顾最近的收入和支出',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({required this.selectedType, required this.onSelected});

  final _ExpenseRangeType selectedType;
  final ValueChanged<_ExpenseRangeType> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _ExpenseRangeType.values.map((type) {
        return _RangeChip(
          label: _labelFor(type),
          selected: selectedType == type,
          onTap: () => onSelected(type),
        );
      }).toList(),
    );
  }

  String _labelFor(_ExpenseRangeType type) {
    return switch (type) {
      _ExpenseRangeType.last7Days => '近 7 天',
      _ExpenseRangeType.last30Days => '近 30 天',
      _ExpenseRangeType.thisMonth => '本月',
      _ExpenseRangeType.lastMonth => '上月',
      _ExpenseRangeType.custom => '自定义',
    };
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.roseDeep
              : AppColors.milk.withValues(alpha: 0.76),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? AppColors.roseDeep
                : AppColors.line.withValues(alpha: 0.85),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.summary,
    required this.isLoading,
  });

  final String title;
  final ExpenseSummary summary;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final balance = summary.balance;
    final balanceLabel = balance < 0
        ? '本期多花了 ${ExpenseSummaryUtils.formatMoney(balance)}'
        : '本期结余 ${ExpenseSummaryUtils.formatMoney(balance)}';

    return WarmCard(
      color: AppColors.blush.withValues(alpha: 0.42),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.milk.withValues(alpha: 0.86),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.savings_outlined,
                  color: AppColors.roseDeep,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      summary.hasEntries ? balanceLabel : '这段时间还没有小账记录',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (isLoading)
            const LinearProgressIndicator(color: AppColors.roseDeep)
          else
            Row(
              children: [
                Expanded(
                  child: _SummaryNumber(
                    label: '总支出',
                    value: ExpenseSummaryUtils.formatMoney(
                      summary.totalExpense,
                    ),
                    color: AppColors.roseDeep,
                  ),
                ),
                Expanded(
                  child: _SummaryNumber(
                    label: '总收入',
                    value: ExpenseSummaryUtils.formatMoney(summary.totalIncome),
                    color: AppColors.lavenderDeep,
                  ),
                ),
                Expanded(
                  child: _SummaryNumber(
                    label: '结余',
                    value:
                        '${balance < 0 ? '-' : ''}${ExpenseSummaryUtils.formatMoney(balance)}',
                    color: balance < 0
                        ? AppColors.roseDeep
                        : const Color(0xFF6AA978),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _SummaryNumber extends StatelessWidget {
  const _SummaryNumber({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.muted,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}

class _ExpenseGroupList extends StatelessWidget {
  const _ExpenseGroupList({required this.groups, required this.onOpenDate});

  final List<ExpenseDateGroup> groups;
  final ValueChanged<DateTime> onOpenDate;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: groups.map((group) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _ExpenseDateCard(
            group: group,
            onTap: () => onOpenDate(group.date),
          ),
        );
      }).toList(),
    );
  }
}

class _ExpenseDateCard extends StatelessWidget {
  const _ExpenseDateCard({required this.group, required this.onTap});

  final ExpenseDateGroup group;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: WarmCard(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${CalendarUtils.formatMonthDay(group.date)} · ${CalendarUtils.weekdayName(group.date)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.muted.withValues(alpha: 0.62),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...group.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ExpenseDetailRow(entry: entry),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpenseDetailRow extends StatelessWidget {
  const _ExpenseDetailRow({required this.entry});

  final ExpenseEntry entry;

  @override
  Widget build(BuildContext context) {
    final label = entry.isIncome ? '收入' : '支出';
    final color = entry.isIncome ? AppColors.lavenderDeep : AppColors.roseDeep;
    final note = entry.note.trim();

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          ExpenseSummaryUtils.formatMoney(entry.amount),
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: AppColors.ink, fontSize: 15),
        ),
        if (note.isNotEmpty) ...[
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              note,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
            ),
          ),
        ] else
          const Spacer(),
      ],
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const WarmCard(
      child: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 22),
          child: CircularProgressIndicator(color: AppColors.roseDeep),
        ),
      ),
    );
  }
}

class _EmptyExpenseCard extends StatelessWidget {
  const _EmptyExpenseCard();

  @override
  Widget build(BuildContext context) {
    return WarmCard(
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.blush.withValues(alpha: 0.58),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              color: AppColors.roseDeep,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '这段时间还没有小账记录',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            '在某一天记一笔，就能在这里轻轻回顾啦',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}
