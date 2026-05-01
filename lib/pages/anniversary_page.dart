import 'package:flutter/material.dart';
import 'package:pink_diary_calendar/models/anniversary.dart';
import 'package:pink_diary_calendar/pages/add_anniversary_page.dart';
import 'package:pink_diary_calendar/services/local_storage_service.dart';
import 'package:pink_diary_calendar/theme/app_colors.dart';
import 'package:pink_diary_calendar/utils/anniversary_utils.dart';
import 'package:pink_diary_calendar/utils/calendar_utils.dart';
import 'package:pink_diary_calendar/widgets/warm_card.dart';
import 'package:pink_diary_calendar/widgets/warm_page_scaffold.dart';
import 'package:pink_diary_calendar/widgets/warm_page_title.dart';

class AnniversaryPage extends StatefulWidget {
  const AnniversaryPage({super.key});

  @override
  State<AnniversaryPage> createState() => _AnniversaryPageState();
}

class _AnniversaryPageState extends State<AnniversaryPage> {
  final LocalStorageService _storageService = const LocalStorageService();

  List<Anniversary> _anniversaries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnniversaries();
  }

  Future<void> _loadAnniversaries() async {
    final anniversaries = await _storageService.loadAnniversaries();
    if (!mounted) {
      return;
    }

    setState(() {
      _anniversaries = AnniversaryUtils.sortAnniversaries(anniversaries);
      _isLoading = false;
    });
  }

  Future<void> _openEditor({Anniversary? anniversary}) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => AddAnniversaryPage(
          anniversary: anniversary,
          storageService: _storageService,
        ),
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    await _loadAnniversaries();
    if (!mounted) {
      return;
    }

    final message = result == 'deleted' ? '这个重要日子已经轻轻移除了' : '这个重要日子已经被收藏啦';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final upcomingAnniversaries = _anniversaries
        .where((anniversary) => !AnniversaryUtils.isOneTimePast(anniversary))
        .toList();
    final pastAnniversaries = _anniversaries
        .where((anniversary) => AnniversaryUtils.isOneTimePast(anniversary))
        .toList();

    return WarmPageScaffold(
      child: ListView(
        key: const PageStorageKey('anniversary-page'),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
        children: [
          const WarmPageTitle(
            title: '重要的日子',
            subtitle: '把值得期待的日子，轻轻放在这里',
            icon: Icons.favorite_rounded,
            iconColor: AppColors.rose,
          ),
          const SizedBox(height: 18),
          if (_isLoading)
            const _LoadingCard()
          else if (_anniversaries.isEmpty)
            _EmptyAnniversaryState(onAdd: () => _openEditor())
          else ...[
            if (upcomingAnniversaries.isEmpty)
              const _NoUpcomingCard()
            else
              ...upcomingAnniversaries.map(
                (anniversary) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _AnniversaryCard(
                    anniversary: anniversary,
                    onTap: () => _openEditor(anniversary: anniversary),
                  ),
                ),
              ),
            _BottomAddAnniversaryButton(onAdd: () => _openEditor()),
            if (pastAnniversaries.isNotEmpty) ...[
              const SizedBox(height: 22),
              const _SectionHeader(title: '已过去'),
              const SizedBox(height: 10),
              ...pastAnniversaries.map(
                (anniversary) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _AnniversaryCard(
                    anniversary: anniversary,
                    onTap: () => _openEditor(anniversary: anniversary),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
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

class _EmptyAnniversaryState extends StatelessWidget {
  const _EmptyAnniversaryState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return WarmCard(
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 28),
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.blush.withValues(alpha: 0.95),
                  AppColors.lavender.withValues(alpha: 0.88),
                ],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.roseDeep,
              size: 34,
            ),
          ),
          const SizedBox(height: 22),
          Text(
            '还没有显示记录的重要日子\n添加一个想被记住的瞬间吧',
            textAlign: TextAlign.center,
            style: textTheme.titleMedium?.copyWith(height: 1.5),
          ),
          const SizedBox(height: 10),
          Text(
            '把想念、生日和约定都留给未来的你。',
            textAlign: TextAlign.center,
            style: textTheme.bodyMedium?.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 26),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('添加纪念日'),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoUpcomingCard extends StatelessWidget {
  const _NoUpcomingCard();

  @override
  Widget build(BuildContext context) {
    return WarmCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.blush.withValues(alpha: 0.72),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_available_rounded,
              color: AppColors.roseDeep,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '最近没有待来的重要日子',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  '过期的一次性日子会留在下面，新的期待可以继续收藏。',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomAddAnniversaryButton extends StatelessWidget {
  const _BottomAddAnniversaryButton({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          key: const ValueKey('add-anniversary-list-button'),
          onPressed: onAdd,
          icon: const Icon(Icons.add_rounded),
          label: const Text('添加纪念日'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.roseDeep,
            backgroundColor: AppColors.milk.withValues(alpha: 0.72),
            side: BorderSide(color: AppColors.line.withValues(alpha: 0.9)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(color: AppColors.muted, fontSize: 15),
      ),
    );
  }
}

class _AnniversaryCard extends StatelessWidget {
  const _AnniversaryCard({required this.anniversary, required this.onTap});

  final Anniversary anniversary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dateInfo = AnniversaryUtils.dateInfo(anniversary);
    final theme = AnniversaryUtils.themeById(anniversary.themeColor);
    final date = AnniversaryUtils.parseDateKey(anniversary.date);
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: WarmCard(
        padding: EdgeInsets.zero,
        color: theme.softColor.withValues(alpha: 0.86),
        border: Border.all(color: Colors.white.withValues(alpha: 0.82)),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 18, 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.softColor.withValues(alpha: 0.96),
                AppColors.milk.withValues(alpha: 0.9),
              ],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: Center(
                      child: Text(
                        AnniversaryUtils.typeIcon(anniversary.type),
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          anniversary.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleLarge,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          date == null
                              ? anniversary.date
                              : CalendarUtils.formatFullDate(date),
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.muted.withValues(alpha: 0.6),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Text(
                      dateInfo.label,
                      style: textTheme.headlineSmall?.copyWith(
                        color: theme.color,
                        fontSize: 30,
                      ),
                    ),
                  ),
                  _TypePill(label: anniversary.type, color: theme.color),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (anniversary.repeatYearly)
                    const _InfoPill(icon: Icons.repeat_rounded, label: '每年重复'),
                  _InfoPill(
                    icon: Icons.notifications_none_rounded,
                    label: AnniversaryUtils.reminderLabel(
                      anniversary.remindBeforeDays,
                    ),
                  ),
                  if (anniversary.note.isNotEmpty)
                    const _InfoPill(
                      icon: Icons.sticky_note_2_outlined,
                      label: '有备注',
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypePill extends StatelessWidget {
  const _TypePill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.muted, size: 15),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.muted,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
