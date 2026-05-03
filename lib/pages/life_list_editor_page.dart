import 'package:flutter/material.dart';
import 'package:pink_diary_calendar/models/life_list.dart';
import 'package:pink_diary_calendar/services/local_storage_service.dart';
import 'package:pink_diary_calendar/theme/app_colors.dart';
import 'package:pink_diary_calendar/widgets/warm_card.dart';
import 'package:pink_diary_calendar/widgets/warm_page_scaffold.dart';

class LifeListEditorTypeInfo {
  const LifeListEditorTypeInfo({
    required this.type,
    required this.title,
    required this.prompt,
    required this.titleHint,
    required this.itemHint,
    required this.icon,
    required this.color,
    required this.softColor,
  });

  final String type;
  final String title;
  final String prompt;
  final String titleHint;
  final String itemHint;
  final IconData icon;
  final Color color;
  final Color softColor;
}

class LifeListEditorPage extends StatefulWidget {
  const LifeListEditorPage({
    required this.typeInfo,
    this.lifeList,
    this.storageService = const LocalStorageService(),
    super.key,
  });

  final LifeListEditorTypeInfo typeInfo;
  final LifeList? lifeList;
  final LocalStorageService storageService;

  @override
  State<LifeListEditorPage> createState() => _LifeListEditorPageState();
}

class _LifeListEditorPageState extends State<LifeListEditorPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _itemController = TextEditingController();

  List<LifeListItem> _items = [];
  bool _isSaving = false;

  bool get _isEditing => widget.lifeList != null;

  @override
  void initState() {
    super.initState();
    final lifeList = widget.lifeList;
    if (lifeList != null) {
      _titleController.text = lifeList.title;
      _items = List<LifeListItem>.from(lifeList.items);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _itemController.dispose();
    super.dispose();
  }

  void _addItem() {
    final text = _itemController.text.trim();
    if (text.isEmpty) {
      _showTip('写点想记录的内容吧');
      return;
    }

    final now = DateTime.now();
    setState(() {
      _items = [
        ..._items,
        LifeListItem(
          id: 'life-item-${now.microsecondsSinceEpoch}',
          text: text,
          done: false,
          createdAt: now,
        ),
      ];
      _itemController.clear();
    });
  }

  void _toggleItem(String id) {
    setState(() {
      _items = _items.map((item) {
        return item.id == id ? item.copyWith(done: !item.done) : item;
      }).toList();
    });
  }

  void _deleteItem(String id) {
    setState(() {
      _items = _items.where((item) => item.id != id).toList();
    });
  }

  List<LifeListItem> _itemsIncludingPendingText(DateTime now) {
    final pendingText = _itemController.text.trim();
    if (pendingText.isEmpty) {
      return _items;
    }

    return [
      ..._items,
      LifeListItem(
        id: 'life-item-${now.microsecondsSinceEpoch}',
        text: pendingText,
        done: false,
        createdAt: now,
      ),
    ];
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showTip('给这份清单取个名字吧');
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    final now = DateTime.now();
    final nextItems = _itemsIncludingPendingText(now);
    final current = widget.lifeList;
    final lifeList = LifeList(
      id: current?.id ?? 'life-list-${now.microsecondsSinceEpoch}',
      type: widget.typeInfo.type,
      title: title,
      items: nextItems,
      note: current?.note ?? '',
      createdAt: current?.createdAt ?? now,
      updatedAt: now,
    );

    try {
      if (_isEditing) {
        await widget.storageService.updateLifeList(lifeList);
      } else {
        await widget.storageService.addLifeList(lifeList);
      }
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isSaving = false);
      _showTip('保存失败，请稍后再试');
    }
  }

  Future<void> _confirmDelete() async {
    final lifeList = widget.lifeList;
    if (lifeList == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.milk,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text('删除清单'),
          content: const Text('确定要删除这份清单吗？'),
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

    await widget.storageService.deleteLifeList(lifeList.id);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop(true);
  }

  void _showTip(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.transparent,
      body: WarmPageScaffold(
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, 22, 20, 28 + bottomInset),
          children: [
            _EditorHeader(
              title: widget.typeInfo.title,
              subtitle: widget.typeInfo.prompt,
              icon: widget.typeInfo.icon,
              color: widget.typeInfo.color,
              onBack: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(height: 18),
            WarmCard(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
              color: widget.typeInfo.softColor.withValues(alpha: 0.44),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: _inputDecoration(
                      '清单标题，例如「${widget.typeInfo.titleHint}」',
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _itemController,
                          decoration: _inputDecoration(
                            widget.typeInfo.itemHint,
                          ),
                          onSubmitted: (_) => _addItem(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _RoundAddButton(onTap: _addItem),
                    ],
                  ),
                ],
              ),
            ),
            if (_items.isNotEmpty) ...[
              const SizedBox(height: 16),
              WarmCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '清单内容',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._items.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ChecklistItemTile(
                          item: item,
                          color: widget.typeInfo.color,
                          onToggle: () => _toggleItem(item.id),
                          onDelete: () => _deleteItem(item.id),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: Icon(
                  _isSaving
                      ? Icons.hourglass_empty_rounded
                      : Icons.save_rounded,
                ),
                label: Text(_isSaving ? '正在保存' : '保存'),
              ),
            ),
            if (_isEditing) ...[
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: _confirmDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('删除这份清单'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.roseDeep,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EditorHeader extends StatelessWidget {
  const _EditorHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
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
                color: AppColors.milk.withValues(alpha: 0.88),
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
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.milk.withValues(alpha: 0.86),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 5),
              Text(
                subtitle,
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

class _RoundAddButton extends StatelessWidget {
  const _RoundAddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 26,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.blush.withValues(alpha: 0.9),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.add_rounded, color: AppColors.roseDeep),
      ),
    );
  }
}

class _ChecklistItemTile extends StatelessWidget {
  const _ChecklistItemTile({
    required this.item,
    required this.color,
    required this.onToggle,
    required this.onDelete,
  });

  final LifeListItem item;
  final Color color;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.cream.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line.withValues(alpha: 0.8)),
      ),
      child: Row(
        children: [
          InkResponse(
            onTap: onToggle,
            radius: 22,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: item.done
                    ? color.withValues(alpha: 0.72)
                    : AppColors.milk,
                borderRadius: BorderRadius.circular(11),
                border: Border.all(color: color.withValues(alpha: 0.42)),
              ),
              child: item.done
                  ? const Icon(
                      Icons.check_rounded,
                      color: AppColors.ink,
                      size: 18,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item.text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: item.done ? AppColors.muted : AppColors.ink,
                decoration: item.done ? TextDecoration.lineThrough : null,
                decorationColor: AppColors.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.close_rounded, color: AppColors.roseDeep),
            tooltip: '删除',
          ),
        ],
      ),
    );
  }
}

InputDecoration _inputDecoration(String hintText) {
  return InputDecoration(
    hintText: hintText,
    hintStyle: TextStyle(color: AppColors.muted.withValues(alpha: 0.75)),
    filled: true,
    fillColor: AppColors.milk.withValues(alpha: 0.78),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: BorderSide(color: AppColors.line.withValues(alpha: 0.8)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: BorderSide(color: AppColors.line.withValues(alpha: 0.8)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: const BorderSide(color: AppColors.roseDeep, width: 1.2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}
