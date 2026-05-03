import 'package:flutter/material.dart';
import 'package:pink_diary_calendar/models/life_list.dart';
import 'package:pink_diary_calendar/pages/life_list_editor_page.dart';
import 'package:pink_diary_calendar/services/local_storage_service.dart';
import 'package:pink_diary_calendar/theme/app_colors.dart';
import 'package:pink_diary_calendar/theme/app_theme.dart';
import 'package:pink_diary_calendar/utils/calendar_utils.dart';
import 'package:pink_diary_calendar/widgets/warm_card.dart';
import 'package:pink_diary_calendar/widgets/warm_page_scaffold.dart';

class LifeListPage extends StatefulWidget {
  const LifeListPage({
    this.storageService = const LocalStorageService(),
    super.key,
  });

  final LocalStorageService storageService;

  @override
  State<LifeListPage> createState() => _LifeListPageState();
}

class _LifeListPageState extends State<LifeListPage> {
  List<LifeListCategory> _categories = [];
  List<LifeList> _lifeLists = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOverview();
  }

  Future<void> _loadOverview() async {
    final categories = await widget.storageService.loadLifeListCategories();
    final lifeLists = await widget.storageService.loadLifeLists();
    if (!mounted) {
      return;
    }
    setState(() {
      _categories = categories;
      _lifeLists = lifeLists;
      _isLoading = false;
    });
  }

  Future<void> _openTypePage(LifeListTypeInfo info) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            LifeListTypePage(info: info, storageService: widget.storageService),
      ),
    );
    if (!mounted) {
      return;
    }
    await _loadOverview();
  }

  Future<void> _openEditor({
    required LifeListTypeInfo info,
    LifeList? lifeList,
  }) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => LifeListEditorPage(
          typeInfo: info.toEditorInfo(),
          lifeList: lifeList,
          storageService: widget.storageService,
        ),
      ),
    );
    if (!mounted) {
      return;
    }
    await _loadOverview();
    if (saved == true && mounted) {
      _showTip('这份清单已经保存好啦');
    }
  }

  Future<void> _toggleRecentItem(_RecentLifeItem recentItem) async {
    final nextItems = recentItem.lifeList.items.map((item) {
      return item.id == recentItem.item.id
          ? item.copyWith(done: !item.done)
          : item;
    }).toList();
    await widget.storageService.updateLifeList(
      recentItem.lifeList.copyWith(items: nextItems, updatedAt: DateTime.now()),
    );
    if (!mounted) {
      return;
    }
    await _loadOverview();
  }

  Future<void> _showCreateMenu() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _CreateActionSheet(
          onCreateList: () => Navigator.of(context).pop('list'),
          onCreateCategory: () => Navigator.of(context).pop('category'),
        );
      },
    );

    if (!mounted || action == null) {
      return;
    }
    if (action == 'list') {
      await _showCategoryPickerForNewList();
    } else {
      await _showCreateCategoryDialog();
    }
  }

  Future<void> _showCategoryPickerForNewList() async {
    final category = await showModalBottomSheet<LifeListCategory>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _CategoryPickerSheet(categories: _categories);
      },
    );
    if (!mounted || category == null) {
      return;
    }
    await _openEditor(info: LifeListTypeInfo.fromCategory(category));
  }

  Future<void> _showCreateCategoryDialog() async {
    final category = await showDialog<LifeListCategory>(
      context: context,
      builder: (context) => const _CreateCategoryDialog(),
    );
    if (category == null) {
      return;
    }

    try {
      await widget.storageService.addLifeListCategory(category);
      if (!mounted) {
        return;
      }
      await _loadOverview();
      _showTip('新的分类已经保存好啦');
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showTip('保存失败，请稍后再试');
    }
  }

  Future<void> _deleteCategory(LifeListCategory category) async {
    if (category.isBuiltIn) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.milk,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          title: const Text('删除分类'),
          content: Text('确定要删除「${category.name}」吗？这个分类下的清单也会一起删除。'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('删除'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await widget.storageService.deleteLifeListCategory(
        category.id,
        deleteLists: true,
      );
      if (!mounted) {
        return;
      }
      await _loadOverview();
      _showTip('分类已删除');
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showTip('删除失败，请稍后再试');
    }
  }

  List<_RecentLifeItem> _recentItems() {
    final categoryById = {
      for (final category in _categories) category.id: category,
    };
    final items = <_RecentLifeItem>[];
    for (final lifeList in _lifeLists) {
      final category =
          categoryById[lifeList.categoryId] ??
          LifeListCategory(
            id: lifeList.categoryId,
            name: lifeList.categoryId,
            icon: 'list',
            colorKey: 'blue',
            isBuiltIn: false,
            createdAt: lifeList.createdAt,
            updatedAt: lifeList.updatedAt,
          );
      for (final item in lifeList.items.where((entry) => !entry.done)) {
        items.add(
          _RecentLifeItem(category: category, lifeList: lifeList, item: item),
        );
      }
    }
    items.sort((first, second) {
      final updatedCompare = second.lifeList.updatedAt.compareTo(
        first.lifeList.updatedAt,
      );
      if (updatedCompare != 0) {
        return updatedCompare;
      }
      return second.item.createdAt.compareTo(first.item.createdAt);
    });
    return items.take(8).toList();
  }

  int _unfinishedCountForCategory(String categoryId) {
    return _lifeLists
        .where((entry) => entry.categoryId == categoryId)
        .fold<int>(0, (count, list) => count + list.unfinishedCount);
  }

  DateTime? _latestUpdatedAtForCategory(String categoryId) {
    final lists = _lifeLists
        .where((entry) => entry.categoryId == categoryId)
        .toList();
    if (lists.isEmpty) {
      return null;
    }
    lists.sort((first, second) => second.updatedAt.compareTo(first.updatedAt));
    return lists.first.updatedAt;
  }

  void _showTip(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final recentItems = _recentItems();

    return _LifeScaffold(
      title: '生活清单',
      subtitle: '把想买的、想学的、想去的，都轻轻整理好',
      trailing: _RoundHeaderButton(
        icon: Icons.add_rounded,
        tooltip: '新建',
        onPressed: _showCreateMenu,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isLoading)
            const _LoadingCard()
          else ...[
            _SectionLabel(title: '最近事项', icon: Icons.auto_awesome_rounded),
            const SizedBox(height: 10),
            if (recentItems.isEmpty)
              const _OverviewEmptyCard()
            else
              WarmCard(
                padding: const EdgeInsets.all(14),
                color: _neutralCardColor(context, const Color(0xFFEDF7F0)),
                child: Column(
                  children: recentItems.map((recentItem) {
                    return _RecentItemTile(
                      recentItem: recentItem,
                      onToggle: () => _toggleRecentItem(recentItem),
                      onTap: () => _openEditor(
                        info: LifeListTypeInfo.fromCategory(
                          recentItem.category,
                        ),
                        lifeList: recentItem.lifeList,
                      ),
                    );
                  }).toList(),
                ),
              ),
            const SizedBox(height: 18),
            _SectionLabel(title: '清单分类', icon: Icons.folder_open_rounded),
            const SizedBox(height: 10),
            ..._categories.map((category) {
              final info = LifeListTypeInfo.fromCategory(category);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CategoryPreviewCard(
                  info: info,
                  unfinishedCount: _unfinishedCountForCategory(category.id),
                  latestUpdatedAt: _latestUpdatedAtForCategory(category.id),
                  onTap: () => _openTypePage(info),
                  onDelete: category.isBuiltIn
                      ? null
                      : () => _deleteCategory(category),
                ),
              );
            }),
          ],
        ],
        ),
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
      trailing: _RoundHeaderButton(
        icon: Icons.add_rounded,
        tooltip: '新建清单',
        onPressed: _openEditor,
      ),
      child: Column(
        children: [
          if (_isLoading)
            const _LoadingCard()
          else if (_lifeLists.isEmpty)
            _EmptyLifeListCard(info: widget.info, onCreate: _openEditor)
          else
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
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

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
                if (trailing != null) ...[const SizedBox(width: 10), trailing!],
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

class _CreateActionSheet extends StatelessWidget {
  const _CreateActionSheet({
    required this.onCreateList,
    required this.onCreateCategory,
  });

  final VoidCallback onCreateList;
  final VoidCallback onCreateCategory;

  @override
  Widget build(BuildContext context) {
    return _WarmSheet(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SheetActionTile(
            icon: Icons.note_add_outlined,
            title: '新建清单',
            subtitle: '在某个分类下写一份小清单',
            onTap: onCreateList,
          ),
          _SheetActionTile(
            icon: Icons.create_new_folder_outlined,
            title: '新建分类',
            subtitle: '创建一个你自己的生活类目',
            onTap: onCreateCategory,
          ),
        ],
      ),
    );
  }
}

class _CategoryPickerSheet extends StatelessWidget {
  const _CategoryPickerSheet({required this.categories});

  final List<LifeListCategory> categories;

  @override
  Widget build(BuildContext context) {
    return _WarmSheet(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.62,
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
          Text('选择分类', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ...categories.map((category) {
            final info = LifeListTypeInfo.fromCategory(category);
            return _SheetActionTile(
              icon: info.icon,
              title: info.title,
              subtitle: info.description,
              color: info.color,
              onTap: () => Navigator.of(context).pop(category),
            );
          }),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreateCategoryDialog extends StatefulWidget {
  const _CreateCategoryDialog();

  @override
  State<_CreateCategoryDialog> createState() => _CreateCategoryDialogState();
}

class _CreateCategoryDialogState extends State<_CreateCategoryDialog> {
  final TextEditingController _nameController = TextEditingController();
  String _icon = 'star';
  String _colorKey = 'blue';

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('给这个分类取个名字吧')));
      return;
    }

    final now = DateTime.now();
    Navigator.of(context).pop(
      LifeListCategory(
        id: 'category-${now.microsecondsSinceEpoch}',
        name: name,
        icon: _icon,
        colorKey: _colorKey,
        isBuiltIn: false,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.milk,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
      title: const Text('新建分类'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(hintText: '分类名称'),
            ),
            const SizedBox(height: 16),
            Text('图标', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['game', 'food', 'star'].map((
                iconKey,
              ) {
                final selected = _icon == iconKey;
                return ChoiceChip(
                  selected: selected,
                  label: Icon(_iconForKey(iconKey), size: 18),
                  onSelected: (_) => setState(() => _icon = iconKey),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text('主题色', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: ['blue', 'green', 'sand', 'gray', 'purple'].map((
                colorKey,
              ) {
                final selected = _colorKey == colorKey;
                final color = _colorForKey(colorKey);
                return InkResponse(
                  onTap: () => setState(() => _colorKey = colorKey),
                  radius: 22,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: selected ? AppColors.ink : Colors.white,
                        width: selected ? 2 : 1,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        TextButton(onPressed: _submit, child: const Text('保存')),
      ],
    );
  }
}

class _RecentItemTile extends StatelessWidget {
  const _RecentItemTile({
    required this.recentItem,
    required this.onToggle,
    required this.onTap,
  });

  final _RecentLifeItem recentItem;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final info = LifeListTypeInfo.fromCategory(recentItem.category);
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            InkResponse(
              onTap: onToggle,
              radius: 22,
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.milk.withValues(alpha: 0.86),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: info.color.withValues(alpha: 0.42)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recentItem.item.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${info.title} · ${recentItem.lifeList.title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppColors.muted.withValues(alpha: 0.55),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewEmptyCard extends StatelessWidget {
  const _OverviewEmptyCard();

  @override
  Widget build(BuildContext context) {
    return const WarmCard(child: Text('暂时没有待完成事项，给生活加一个小清单吧'));
  }
}

class _CategoryPreviewCard extends StatelessWidget {
  const _CategoryPreviewCard({
    required this.info,
    required this.unfinishedCount,
    required this.latestUpdatedAt,
    required this.onTap,
    this.onDelete,
  });

  final LifeListTypeInfo info;
  final int unfinishedCount;
  final DateTime? latestUpdatedAt;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: WarmCard(
        padding: const EdgeInsets.all(18),
        color: info.softColor.withValues(alpha: 0.56),
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
                    unfinishedCount > 0 ? '$unfinishedCount 个未完成' : '暂时没有待完成事项',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    latestUpdatedAt == null
                        ? info.description
                        : '更新于 ${CalendarUtils.formatUpdatedTime(latestUpdatedAt!)}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                  ),
                ],
              ),
            ),
            if (onDelete != null)
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                color: AppColors.muted.withValues(alpha: 0.72),
                tooltip: '删除分类',
              )
            else
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final warmColors = Theme.of(context).extension<WarmThemeColors>();
    return Row(
      children: [
        Icon(icon, color: warmColors?.primary ?? AppColors.roseDeep, size: 19),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _RoundHeaderButton extends StatelessWidget {
  const _RoundHeaderButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
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
        radius: 28,
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: (warmColors?.soft ?? AppColors.blush).withValues(alpha: 0.9),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: warmColors?.primary ?? AppColors.roseDeep,
            size: 26,
          ),
        ),
      ),
    );
  }
}

class _SheetActionTile extends StatelessWidget {
  const _SheetActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      leading: Icon(icon, color: color ?? AppColors.roseDeep),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _WarmSheet extends StatelessWidget {
  const _WarmSheet({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
      decoration: const BoxDecoration(
        color: AppColors.milk,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(top: false, child: child),
    );
  }
}

class _RecentLifeItem {
  const _RecentLifeItem({
    required this.category,
    required this.lifeList,
    required this.item,
  });

  final LifeListCategory category;
  final LifeList lifeList;
  final LifeListItem item;
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

  factory LifeListTypeInfo.fromCategory(LifeListCategory category) {
    return switch (category.id) {
      LifeListTypes.shopping => const LifeListTypeInfo(
        type: LifeListTypes.shopping,
        title: '购物清单',
        description: '记录想买的东西，不怕忘记',
        listSubtitle: '把想买的小东西放在这里',
        emptyText: '还没有购物清单，写下想买的小东西吧',
        icon: Icons.shopping_bag_outlined,
        color: Color(0xFF8B9C75),
        softColor: Color(0xFFF8F3E8),
        prompt: '今天想买点什么？',
        titleHint: '周末采购',
        itemHint: '牛奶、纸巾、洗面奶……',
      ),
      LifeListTypes.study => const LifeListTypeInfo(
        type: LifeListTypes.study,
        title: '学习计划',
        description: '整理学习目标和待完成任务',
        listSubtitle: '把学习目标拆成小小一步',
        emptyText: '还没有学习计划，写下想完成的任务吧',
        icon: Icons.menu_book_outlined,
        color: Color(0xFF7FA08A),
        softColor: Color(0xFFEDF7F0),
        prompt: '把想完成的学习任务写下来吧',
        titleHint: '英语四级复习',
        itemHint: '背 30 个单词、做一套听力……',
      ),
      LifeListTypes.travel => const LifeListTypeInfo(
        type: LifeListTypes.travel,
        title: '旅行攻略',
        description: '收藏路线景点美食与准备事项',
        listSubtitle: '把想去的地方慢慢整理好',
        emptyText: '还没有旅行攻略，写下想去的地方吧',
        icon: Icons.flight_takeoff_rounded,
        color: Color(0xFF6F9FC4),
        softColor: Color(0xFFEAF4F8),
        prompt: '把想去的地方和准备事项整理好',
        titleHint: '杭州两日游',
        itemHint: '西湖、灵隐寺、带身份证……',
      ),
      _ => LifeListTypeInfo(
        type: category.id,
        title: category.name,
        description: '你自己创建的生活分类',
        listSubtitle: '把这类小事慢慢整理好',
        emptyText: '还没有清单，写下一点想整理的内容吧',
        icon: _iconForKey(category.icon),
        color: _colorForKey(category.colorKey),
        softColor: _softColorForKey(category.colorKey),
        prompt: '把想整理的事情写下来吧',
        titleHint: '${category.name}清单',
        itemHint: '写点想记录的内容吧……',
      ),
    };
  }

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
}

Color _neutralCardColor(BuildContext context, Color fallback) {
  final warmColors = Theme.of(context).extension<WarmThemeColors>();
  return warmColors?.soft.withValues(alpha: 0.42) ??
      fallback.withValues(alpha: 0.72);
}

IconData _iconForKey(String key) {
  return switch (key) {
    'shopping' => Icons.shopping_bag_outlined,
    'book' => Icons.menu_book_outlined,
    'travel' => Icons.flight_takeoff_rounded,
    'game' => Icons.sports_esports_outlined,
    'food' => Icons.cake_outlined,
    'star' => Icons.auto_awesome_rounded,
    _ => Icons.checklist_rounded,
  };
}

Color _colorForKey(String key) {
  return switch (key) {
    'green' => const Color(0xFF7FA08A),
    'sand' => const Color(0xFFB59B67),
    'gray' => const Color(0xFF9A9A94),
    'purple' => AppColors.lavenderDeep,
    _ => const Color(0xFF6F9FC4),
  };
}

Color _softColorForKey(String key) {
  return switch (key) {
    'green' => const Color(0xFFEDF7F0),
    'sand' => const Color(0xFFF8F3E8),
    'gray' => const Color(0xFFF3F3F1),
    'purple' => const Color(0xFFF2EDFA),
    _ => const Color(0xFFEAF4F8),
  };
}
