import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pink_diary_calendar/models/daily_record.dart';
import 'package:pink_diary_calendar/services/local_storage_service.dart';
import 'package:pink_diary_calendar/theme/app_colors.dart';
import 'package:pink_diary_calendar/utils/calendar_utils.dart';
import 'package:pink_diary_calendar/widgets/warm_card.dart';
import 'package:pink_diary_calendar/widgets/warm_page_scaffold.dart';

class DayDetailPage extends StatefulWidget {
  const DayDetailPage({
    required this.date,
    this.storageService = const LocalStorageService(),
    super.key,
  });

  final DateTime date;
  final LocalStorageService storageService;

  @override
  State<DayDetailPage> createState() => _DayDetailPageState();
}

class _DayDetailPageState extends State<DayDetailPage> {
  static const List<String> _prompts = [
    '今天想留下些什么？',
    '一句话也可以。',
    '把今天轻轻放在这里吧。',
    '今天有没有一个值得记住的小瞬间？',
    '未来的这一天，想提醒自己什么？',
    '不用写很多，几个词也可以。',
    '今天的空白，也可以被温柔保存。',
    '写给今天的自己一句话吧。',
  ];

  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _controller = TextEditingController();

  late final DateTime _date;
  late final String _dateKey;
  late int _promptIndex;

  DailyRecord? _record;
  List<String> _images = [];
  List<ExpenseEntry> _expenses = [];
  List<LittleJoyEntry> _littleJoys = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _date = CalendarUtils.dateOnly(widget.date);
    _dateKey = CalendarUtils.formatDateKey(_date);
    _promptIndex = (_date.year + _date.month + _date.day) % _prompts.length;
    _loadRecord();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadRecord() async {
    final record = await widget.storageService.loadDailyRecord(_dateKey);
    if (!mounted) {
      return;
    }

    setState(() {
      _record = record;
      _controller.text = record?.text ?? '';
      _images = List<String>.from(record?.images ?? const []);
      _expenses = List<ExpenseEntry>.from(record?.expenses ?? const []);
      _littleJoys = List<LittleJoyEntry>.from(record?.littleJoys ?? const []);
      _isLoading = false;
    });
  }

  void _changePrompt() {
    setState(() {
      _promptIndex = (_promptIndex + 1) % _prompts.length;
    });
  }

  Future<void> _addImage() async {
    try {
      final pickedImage = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
      );
      if (pickedImage == null) {
        return;
      }

      final savedPath = await _copyImageToAppDirectory(pickedImage);
      if (!mounted) {
        return;
      }
      setState(() {
        _images = [..._images, savedPath];
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('图片选择失败，请稍后再试')));
    }
  }

  Future<String> _copyImageToAppDirectory(XFile pickedImage) async {
    final directory = await getApplicationDocumentsDirectory();
    final imageDirectory = Directory(
      '${directory.path}${Platform.pathSeparator}daily_images',
    );
    if (!await imageDirectory.exists()) {
      await imageDirectory.create(recursive: true);
    }

    final extension = _fileExtension(pickedImage.name);
    final fileName =
        'daily_$_dateKey-${DateTime.now().microsecondsSinceEpoch}$extension';
    final targetPath =
        '${imageDirectory.path}${Platform.pathSeparator}$fileName';
    await File(pickedImage.path).copy(targetPath);
    return targetPath;
  }

  String _fileExtension(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == fileName.length - 1) {
      return '.jpg';
    }
    return fileName.substring(dotIndex);
  }

  void _removeImage(String imagePath) {
    setState(() {
      _images = _images.where((path) => path != imagePath).toList();
    });
  }

  Future<void> _showExpenseSheet() async {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    var selectedType = 'expense';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final inset = MediaQuery.viewInsetsOf(sheetContext).bottom;
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return _WarmBottomSheet(
              bottomInset: inset,
              title: '记一笔',
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _TypeChoice(
                          label: '支出',
                          selected: selectedType == 'expense',
                          onTap: () {
                            setSheetState(() => selectedType = 'expense');
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _TypeChoice(
                          label: '收入',
                          selected: selectedType == 'income',
                          onTap: () {
                            setSheetState(() => selectedType = 'income');
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: _softInputDecoration('金额'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    decoration: _softInputDecoration('说明，可以留空'),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final amount = double.tryParse(
                          amountController.text.trim(),
                        );
                        if (amount == null || amount <= 0) {
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              const SnackBar(content: Text('请输入正确的金额')),
                            );
                          return;
                        }

                        final entry = ExpenseEntry(
                          id: _newEntryId('expense'),
                          amount: amount,
                          note: noteController.text.trim(),
                          type: selectedType,
                          createdAt: DateTime.now(),
                        );
                        setState(() {
                          _expenses = [..._expenses, entry];
                        });
                        Navigator.of(sheetContext).pop();
                      },
                      child: const Text('确定'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    amountController.dispose();
    noteController.dispose();
  }

  Future<void> _showLittleJoySheet() async {
    final joyController = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final inset = MediaQuery.viewInsetsOf(sheetContext).bottom;
        return _WarmBottomSheet(
          bottomInset: inset,
          title: '小确幸',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: joyController,
                minLines: 4,
                maxLines: 6,
                decoration: _softInputDecoration('写下一件今天值得记住的小事吧'),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final text = joyController.text.trim();
                    if (text.isEmpty) {
                      Navigator.of(sheetContext).pop();
                      return;
                    }

                    final entry = LittleJoyEntry(
                      id: _newEntryId('joy'),
                      text: text,
                      createdAt: DateTime.now(),
                    );
                    setState(() {
                      _littleJoys = [..._littleJoys, entry];
                    });
                    Navigator.of(sheetContext).pop();
                  },
                  child: const Text('确定'),
                ),
              ),
            ],
          ),
        );
      },
    );

    joyController.dispose();
  }

  InputDecoration _softInputDecoration(String hintText) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: AppColors.muted.withValues(alpha: 0.72)),
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

  String _newEntryId(String prefix) {
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}';
  }

  Future<void> _saveRecord() async {
    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    final record = DailyRecord(
      date: _dateKey,
      text: _controller.text,
      images: _images,
      expenses: _expenses,
      littleJoys: _littleJoys,
      updatedAt: DateTime.now(),
    );

    try {
      await widget.storageService.saveDailyRecord(record);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('保存失败，请稍后再试')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.transparent,
      body: WarmPageScaffold(
        child: ListView(
          key: const PageStorageKey('day-detail-page'),
          padding: EdgeInsets.fromLTRB(20, 22, 20, 28 + bottomInset),
          children: [
            _DetailHeader(
              date: _date,
              onBack: () => Navigator.of(context).maybePop(),
            ),
            const SizedBox(height: 18),
            WarmCard(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PromptBar(
                    prompt: _prompts[_promptIndex],
                    onChangePrompt: _changePrompt,
                  ),
                  if (_record != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      '上次收藏于 ${CalendarUtils.formatUpdatedTime(_record!.updatedAt)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  _PaperTextField(
                    controller: _controller,
                    enabled: !_isLoading && !_isSaving,
                  ),
                  const SizedBox(height: 16),
                  _QuickActionBar(
                    onAddImage: _addImage,
                    onAddExpense: _showExpenseSheet,
                    onAddLittleJoy: _showLittleJoySheet,
                  ),
                ],
              ),
            ),
            if (_images.isNotEmpty) ...[
              const SizedBox(height: 18),
              _PhotoSection(images: _images, onRemove: _removeImage),
            ],
            if (_expenses.isNotEmpty) ...[
              const SizedBox(height: 18),
              _ExpenseSection(
                expenses: _expenses,
                onRemove: (id) {
                  setState(() {
                    _expenses = _expenses
                        .where((entry) => entry.id != id)
                        .toList();
                  });
                },
              ),
            ],
            if (_littleJoys.isNotEmpty) ...[
              const SizedBox(height: 18),
              _LittleJoySection(
                littleJoys: _littleJoys,
                onRemove: (id) {
                  setState(() {
                    _littleJoys = _littleJoys
                        .where((entry) => entry.id != id)
                        .toList();
                  });
                },
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                key: const ValueKey('save-daily-record-button'),
                onPressed: _isSaving ? null : _saveRecord,
                icon: Icon(
                  _isSaving
                      ? Icons.hourglass_empty_rounded
                      : Icons.favorite_rounded,
                ),
                label: Text(_isSaving ? '正在收藏' : '保存'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.date, required this.onBack});

  final DateTime date;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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
              Text(
                CalendarUtils.formatMonthDayWithWeekday(date),
                style: textTheme.headlineSmall,
              ),
              const SizedBox(height: 5),
              Text(
                CalendarUtils.formatFullDate(date),
                style: textTheme.bodyMedium?.copyWith(color: AppColors.muted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PromptBar extends StatelessWidget {
  const _PromptBar({required this.prompt, required this.onChangePrompt});

  final String prompt;
  final VoidCallback onChangePrompt;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: AppColors.blush.withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.roseDeep,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              prompt,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontSize: 15, height: 1.35),
            ),
          ),
          TextButton.icon(
            onPressed: onChangePrompt,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('换一句'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.roseDeep,
              visualDensity: VisualDensity.compact,
              textStyle: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaperTextField extends StatelessWidget {
  const _PaperTextField({required this.controller, required this.enabled});

  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final inputHeight = (MediaQuery.sizeOf(context).height * 0.42).clamp(
      300.0,
      500.0,
    );

    return Container(
      height: inputHeight,
      decoration: BoxDecoration(
        color: AppColors.cream.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.line.withValues(alpha: 0.8)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _PaperLinePainter(
                  lineColor: AppColors.rose.withValues(alpha: 0.16),
                ),
              ),
            ),
            TextField(
              key: const ValueKey('daily-record-input'),
              controller: controller,
              enabled: enabled,
              expands: true,
              maxLines: null,
              minLines: null,
              keyboardType: TextInputType.multiline,
              textAlignVertical: TextAlignVertical.top,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.ink,
                fontSize: 16,
                height: 1.65,
              ),
              decoration: InputDecoration(
                hintText: '写下今天想留下的任何事情……',
                hintStyle: TextStyle(
                  color: AppColors.muted.withValues(alpha: 0.72),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionBar extends StatelessWidget {
  const _QuickActionBar({
    required this.onAddImage,
    required this.onAddExpense,
    required this.onAddLittleJoy,
  });

  final VoidCallback onAddImage;
  final VoidCallback onAddExpense;
  final VoidCallback onAddLittleJoy;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _QuickActionButton(
          icon: Icons.photo_outlined,
          label: '添加图片',
          onTap: onAddImage,
        ),
        _QuickActionButton(
          icon: Icons.receipt_long_outlined,
          label: '记一笔',
          onTap: onAddExpense,
        ),
        _QuickActionButton(
          icon: Icons.wb_sunny_outlined,
          label: '小确幸',
          onTap: onAddLittleJoy,
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.roseDeep,
        backgroundColor: AppColors.milk.withValues(alpha: 0.74),
        side: BorderSide(color: AppColors.line.withValues(alpha: 0.85)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _PhotoSection extends StatelessWidget {
  const _PhotoSection({required this.images, required this.onRemove});

  final List<String> images;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return WarmCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(icon: Icons.photo_rounded, title: '今日照片'),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: images.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final imagePath = images[index];
              return _PhotoTile(
                imagePath: imagePath,
                onRemove: () => onRemove(imagePath),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.imagePath, required this.onRemove});

  final String imagePath;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.blush.withValues(alpha: 0.5),
              border: Border.all(color: AppColors.line.withValues(alpha: 0.8)),
            ),
            child: Image.file(
              File(imagePath),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      '图片暂时无法显示',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: _MiniDeleteButton(onTap: onRemove),
          ),
        ],
      ),
    );
  }
}

class _ExpenseSection extends StatelessWidget {
  const _ExpenseSection({required this.expenses, required this.onRemove});

  final List<ExpenseEntry> expenses;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return WarmCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(icon: Icons.receipt_long_rounded, title: '今日小账'),
          const SizedBox(height: 12),
          ...expenses.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ExpenseTile(entry: entry, onRemove: onRemove),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({required this.entry, required this.onRemove});

  final ExpenseEntry entry;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    final sign = entry.isIncome ? '+' : '-';
    final amountText = _formatAmount(entry.amount);
    final color = entry.isIncome ? AppColors.lavenderDeep : AppColors.roseDeep;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: AppColors.cream.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.line.withValues(alpha: 0.8)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.blush.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.payments_outlined, color: color, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              entry.displayNote,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontSize: 15),
            ),
          ),
          Text(
            '$sign$amountText 元',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 8),
          _MiniDeleteButton(onTap: () => onRemove(entry.id)),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    final normalizedAmount = amount.abs();
    if (normalizedAmount % 1 == 0) {
      return normalizedAmount.toStringAsFixed(0);
    }
    return normalizedAmount.toStringAsFixed(2);
  }
}

class _LittleJoySection extends StatelessWidget {
  const _LittleJoySection({required this.littleJoys, required this.onRemove});

  final List<LittleJoyEntry> littleJoys;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return WarmCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(icon: Icons.wb_sunny_rounded, title: '今日小确幸'),
          const SizedBox(height: 12),
          ...littleJoys.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _LittleJoyTile(entry: entry, onRemove: onRemove),
            ),
          ),
        ],
      ),
    );
  }
}

class _LittleJoyTile extends StatelessWidget {
  const _LittleJoyTile({required this.entry, required this.onRemove});

  final LittleJoyEntry entry;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 14, 10, 14),
      decoration: BoxDecoration(
        color: AppColors.lavender.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.lavenderDeep,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              entry.text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.ink,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _MiniDeleteButton(onTap: () => onRemove(entry.id)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.roseDeep, size: 20),
        const SizedBox(width: 8),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _MiniDeleteButton extends StatelessWidget {
  const _MiniDeleteButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.88),
      shape: const CircleBorder(),
      child: InkResponse(
        onTap: onTap,
        radius: 18,
        child: const SizedBox(
          width: 28,
          height: 28,
          child: Icon(Icons.close_rounded, color: AppColors.roseDeep, size: 17),
        ),
      ),
    );
  }
}

class _TypeChoice extends StatelessWidget {
  const _TypeChoice({
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
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.roseDeep
              : AppColors.cream.withValues(alpha: 0.76),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? AppColors.roseDeep
                : AppColors.line.withValues(alpha: 0.8),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: selected ? Colors.white : AppColors.ink,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _WarmBottomSheet extends StatelessWidget {
  const _WarmBottomSheet({
    required this.bottomInset,
    required this.title,
    required this.child,
  });

  final double bottomInset;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
        decoration: const BoxDecoration(
          color: AppColors.milk,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _PaperLinePainter extends CustomPainter {
  const _PaperLinePainter({required this.lineColor});

  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;

    const topPadding = 51.0;
    const lineGap = 26.4;
    for (var y = topPadding; y < size.height; y += lineGap) {
      canvas.drawLine(Offset(18, y), Offset(size.width - 18, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _PaperLinePainter oldDelegate) {
    return oldDelegate.lineColor != lineColor;
  }
}
