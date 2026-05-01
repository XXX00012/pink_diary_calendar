import 'package:flutter/material.dart';
import 'package:pink_diary_calendar/models/life_list.dart';
import 'package:pink_diary_calendar/pages/life_list_editor_page.dart';
import 'package:pink_diary_calendar/services/local_storage_service.dart';
import 'package:pink_diary_calendar/theme/app_colors.dart';
import 'package:pink_diary_calendar/utils/calendar_utils.dart';
import 'package:pink_diary_calendar/widgets/warm_card.dart';
import 'package:pink_diary_calendar/widgets/warm_page_scaffold.dart';

class LifeListPage extends StatelessWidget {
  const LifeListPage({
    this.storageService = const LocalStorageService(),
    super.key,
  });

  final LocalStorageService storageService;

  Future<void> _openTypePage(BuildContext context, LifeListTypeInfo info) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            LifeListTypePage(info: info, storageService: storageService),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _LifeScaffold(
      title: '生活清单',
      subtitle: '',
      child: Column(
        children: LifeListTypeInfo.options.map((info) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: _TypeOptionCard(
              info: info,
              onTap: () => _openTypePage(context, info),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class LifeListTypePage extends StatefulWidget {
  const LifeListTypePage({
    required this.info,
    this.storageService = const LocalStorageService(),
    super.key,
  });

  final LifeListTypeInfo info;
  final LocalStorageService storageService;

  @override
  State<LifeListTypePage> createState() => _LifeListTypePageState();
}

class _LifeListTypePageState extends State<LifeListTypePage> {
  List<LifeList> _lifeLists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLifeLists();
  }

  Future<void> _loadLifeLists() async {
    final lifeLists = await widget.storageService.loadLifeListsByType(
      widget.info.type,
    );
    if (!mounted) {
      return;
    }

    setState(() {
      _lifeLists = lifeLists;
      _isLoading = false;
    });
  }

  Future<void> _openEditor({LifeList? lifeList}) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => LifeListEditorPage(
          typeInfo: widget.info.toEditorInfo(),
          lifeList: lifeList,
          storageService: widget.storageService,
        ),
      ),
    );

    if (!mounted) {
      return;
    }

    await _loadLifeLists();
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('这份清单已经保存好啦')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return _LifeScaffold(
      title: widget.info.title,
      subtitle: widget.info.listSubtitle,
      child: Column(
        children: [
          if (_isLoading)
            const _LoadingCard()
          else if (_lifeLists.isEmpty)
            _EmptyLifeListCard(info: widget.info, onCreate: _openEditor)
          else ...[
            ..._lifeLists.map(
              (lifeList) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _LifeListCard(
                  info: widget.info,
                  lifeList: lifeList,
                  onTap: () => _openEditor(lifeList: lifeList),
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _openEditor,
                icon: const Icon(Icons.add_rounded),
                label: const Text('新建'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LifeScaffold extends StatelessWidget {
  const _LifeScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: WarmPageScaffold(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 32),
          children: [
            Row(
              children: [
                Tooltip(
                  message: '返回',
                  child: InkResponse(
                    onTap: () => Navigator.of(context).maybePop(),
                    radius: 28,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: AppColors.milk.withValues(alpha: 0.88),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
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
                      Text(
                        title,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.muted),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

class _TypeOptionCard extends StatelessWidget {
  const _TypeOptionCard({required this.info, required this.onTap});

  final LifeListTypeInfo info;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: WarmCard(
        padding: const EdgeInsets.all(18),
        color: info.softColor.withValues(alpha: 0.64),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.milk.withValues(alpha: 0.86),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(info.icon, color: info.color, size: 25),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    info.description,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
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

class _EmptyLifeListCard extends StatelessWidget {
  const _EmptyLifeListCard({required this.info, required this.onCreate});

  final LifeListTypeInfo info;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return WarmCard(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
      child: Column(
        children: [
          Icon(info.icon, color: info.color, size: 38),
          const SizedBox(height: 16),
          Text(
            info.emptyText,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('新建'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LifeListCard extends StatelessWidget {
  const _LifeListCard({
    required this.info,
    required this.lifeList,
    required this.onTap,
  });

  final LifeListTypeInfo info;
  final LifeList lifeList;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: WarmCard(
        padding: const EdgeInsets.all(18),
        color: info.softColor.withValues(alpha: 0.54),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.milk.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(info.icon, color: info.color, size: 23),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lifeList.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${info.title} · ${lifeList.completedCount}/${lifeList.totalCount} 已完成',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '更新于 ${CalendarUtils.formatUpdatedTime(lifeList.updatedAt)}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
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

class LifeListTypeInfo {
  const LifeListTypeInfo({
    required this.type,
    required this.title,
    required this.description,
    required this.listSubtitle,
    required this.emptyText,
    required this.icon,
    required this.color,
    required this.softColor,
    required this.prompt,
    required this.titleHint,
    required this.itemHint,
  });

  final String type;
  final String title;
  final String description;
  final String listSubtitle;
  final String emptyText;
  final IconData icon;
  final Color color;
  final Color softColor;
  final String prompt;
  final String titleHint;
  final String itemHint;

  LifeListEditorTypeInfo toEditorInfo() {
    return LifeListEditorTypeInfo(
      type: type,
      title: title,
      prompt: prompt,
      titleHint: titleHint,
      itemHint: itemHint,
      icon: icon,
      color: color,
      softColor: softColor,
    );
  }

  static const List<LifeListTypeInfo> options = [
    LifeListTypeInfo(
      type: LifeListTypes.shopping,
      title: '购物清单',
      description: '记录想买的东西，不怕忘记',
      listSubtitle: '把想买的小东西放在这里',
      emptyText: '还没有购物清单，写下想买的小东西吧',
      icon: Icons.shopping_bag_outlined,
      color: AppColors.roseDeep,
      softColor: AppColors.blush,
      prompt: '今天想买点什么？',
      titleHint: '周末采购',
      itemHint: '牛奶、纸巾、洗面奶……',
    ),
    LifeListTypeInfo(
      type: LifeListTypes.study,
      title: '学习计划',
      description: '整理学习目标和待完成任务',
      listSubtitle: '把学习目标拆成小小一步',
      emptyText: '还没有学习计划，写下想完成的任务吧',
      icon: Icons.menu_book_outlined,
      color: AppColors.lavenderDeep,
      softColor: AppColors.lavender,
      prompt: '把想完成的学习任务写下来吧',
      titleHint: '英语四级复习',
      itemHint: '背 30 个单词、做一套听力……',
    ),
    LifeListTypeInfo(
      type: LifeListTypes.travel,
      title: '旅行攻略',
      description: '收藏路线景点美食与准备事项',
      listSubtitle: '把想去的地方慢慢整理好',
      emptyText: '还没有旅行攻略，写下想去的地方吧',
      icon: Icons.flight_takeoff_rounded,
      color: Color(0xFF6F9FC4),
      softColor: Color(0xFFEFF8FF),
      prompt: '把想去的地方和准备事项整理好',
      titleHint: '杭州两日游',
      itemHint: '西湖、灵隐寺、带身份证……',
    ),
  ];
}
