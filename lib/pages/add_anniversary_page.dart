import 'package:flutter/material.dart';
import 'package:pink_diary_calendar/models/anniversary.dart';
import 'package:pink_diary_calendar/services/local_storage_service.dart';
import 'package:pink_diary_calendar/services/notification_service.dart';
import 'package:pink_diary_calendar/theme/app_colors.dart';
import 'package:pink_diary_calendar/utils/anniversary_utils.dart';
import 'package:pink_diary_calendar/utils/calendar_utils.dart';
import 'package:pink_diary_calendar/widgets/warm_card.dart';
import 'package:pink_diary_calendar/widgets/warm_page_scaffold.dart';

class AddAnniversaryPage extends StatefulWidget {
  const AddAnniversaryPage({
    this.anniversary,
    this.storageService = const LocalStorageService(),
    super.key,
  });

  final Anniversary? anniversary;
  final LocalStorageService storageService;

  @override
  State<AddAnniversaryPage> createState() => _AddAnniversaryPageState();
}

class _AddAnniversaryPageState extends State<AddAnniversaryPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  DateTime? _selectedDate;
  String _selectedType = '纪念日';
  bool _repeatYearly = false;
  int _remindBeforeDays = 0;
  String _themeColor = 'blush';
  bool _isSaving = false;

  bool get _isEditing => widget.anniversary != null;

  @override
  void initState() {
    super.initState();
    final anniversary = widget.anniversary;
    if (anniversary != null) {
      _titleController.text = anniversary.title;
      _noteController.text = anniversary.note;
      _selectedDate = AnniversaryUtils.parseDateKey(anniversary.date);
      _selectedType = anniversary.type;
      _repeatYearly = anniversary.repeatYearly;
      _remindBeforeDays = anniversary.remindBeforeDays;
      _themeColor = anniversary.themeColor;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(1900),
      lastDate: DateTime(now.year + 80, 12, 31),
      helpText: '选择重要日子',
      cancelText: '取消',
      confirmText: '确定',
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

    if (pickedDate == null) {
      return;
    }

    setState(() {
      _selectedDate = CalendarUtils.dateOnly(pickedDate);
    });
  }

  void _selectType(String type) {
    setState(() {
      _selectedType = type;
      _repeatYearly = AnniversaryUtils.defaultRepeatYearly(type);
    });
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showTip('给这个日子取个名字吧');
      return;
    }

    final selectedDate = _selectedDate;
    if (selectedDate == null) {
      _showTip('请选择一个日期');
      return;
    }

    setState(() => _isSaving = true);

    final now = DateTime.now();
    final current = widget.anniversary;
    final anniversary = Anniversary(
      id: current?.id ?? 'anniversary-${now.microsecondsSinceEpoch}',
      title: title,
      date: CalendarUtils.formatDateKey(selectedDate),
      type: _selectedType,
      repeatYearly: _repeatYearly,
      remindBeforeDays: _remindBeforeDays,
      themeColor: _themeColor,
      note: _noteController.text.trim(),
      createdAt: current?.createdAt ?? now,
      updatedAt: now,
    );

    try {
      if (_isEditing) {
        await widget.storageService.updateAnniversary(anniversary);
      } else {
        await widget.storageService.addAnniversary(anniversary);
      }
      await _rescheduleAnniversaryNotifications();

      if (!mounted) {
        return;
      }
      Navigator.of(context).pop('saved');
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isSaving = false);
      _showTip('保存失败，请稍后再试');
    }
  }

  Future<void> _confirmDelete() async {
    final anniversary = widget.anniversary;
    if (anniversary == null) {
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
          title: const Text('删除重要日子'),
          content: const Text('确定要删除这个重要日子吗？'),
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

    await widget.storageService.deleteAnniversary(anniversary.id);
    await _rescheduleAnniversaryNotifications();
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop('deleted');
  }

  Future<void> _rescheduleAnniversaryNotifications() async {
    try {
      await NotificationService.instance.rescheduleAnniversaryNotifications(
        storageService: widget.storageService,
      );
    } catch (_) {
      // Saving the anniversary should stay reliable even if system permission
      // or a platform notification channel is temporarily unavailable.
    }
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
            _EditHeader(
              title: _isEditing ? '编辑纪念日' : '添加纪念日',
              subtitle: '把重要的日子，轻轻收进日历里',
              onBack: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(height: 18),
            WarmCard(
              padding: const EdgeInsets.fromLTRB(18, 20, 18, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: _inputDecoration('给这个日子取个名字吧'),
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: _pickDate,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 15,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.cream.withValues(alpha: 0.72),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.line.withValues(alpha: 0.8),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.event_rounded,
                            color: AppColors.roseDeep,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedDate == null
                                  ? '请选择一个日期'
                                  : CalendarUtils.formatFullDate(
                                      _selectedDate!,
                                    ),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: _selectedDate == null
                                        ? AppColors.muted
                                        : AppColors.ink,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _FormLabel(label: '类型'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AnniversaryUtils.types.map((type) {
                      return _SoftChoiceChip(
                        label: '${AnniversaryUtils.typeIcon(type)} $type',
                        selected: _selectedType == type,
                        onTap: () => _selectType(type),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),
                  SwitchListTile(
                    value: _repeatYearly,
                    onChanged: (value) {
                      setState(() => _repeatYearly = value);
                    },
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: AppColors.roseDeep,
                    title: Text(
                      '每年重复',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    subtitle: Text(
                      '适合生日、周年和每年都想记住的日子',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _FormLabel(label: '提醒'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: AnniversaryUtils.reminderOptions.map((days) {
                      return _SoftChoiceChip(
                        label: AnniversaryUtils.reminderLabel(days),
                        selected: _remindBeforeDays == days,
                        onTap: () {
                          setState(() => _remindBeforeDays = days);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),
                  _FormLabel(label: '主题色'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: AnniversaryUtils.themeOptions.map((theme) {
                      return _ThemeDot(
                        option: theme,
                        selected: _themeColor == theme.id,
                        onTap: () {
                          setState(() => _themeColor = theme.id);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _noteController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: _inputDecoration('备注，可以留空'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: Icon(
                  _isSaving
                      ? Icons.hourglass_empty_rounded
                      : Icons.favorite_rounded,
                ),
                label: Text(_isSaving ? '正在收藏' : '保存'),
              ),
            ),
            if (_isEditing) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _confirmDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('删除这个重要日子'),
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

  InputDecoration _inputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: AppColors.muted.withValues(alpha: 0.75)),
      filled: true,
      fillColor: AppColors.cream.withValues(alpha: 0.72),
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
}

class _EditHeader extends StatelessWidget {
  const _EditHeader({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  final String title;
  final String subtitle;
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

class _FormLabel extends StatelessWidget {
  const _FormLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 15),
    );
  }
}

class _SoftChoiceChip extends StatelessWidget {
  const _SoftChoiceChip({
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
              : AppColors.blush.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? AppColors.roseDeep
                : AppColors.line.withValues(alpha: 0.8),
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ThemeDot extends StatelessWidget {
  const _ThemeDot({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final AnniversaryThemeOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: option.label,
      child: InkResponse(
        onTap: onTap,
        radius: 25,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 42,
          height: 42,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: option.softColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? AppColors.roseDeep : Colors.white,
              width: selected ? 2 : 1,
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: option.color,
              shape: BoxShape.circle,
            ),
            child: selected
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                : null,
          ),
        ),
      ),
    );
  }
}
