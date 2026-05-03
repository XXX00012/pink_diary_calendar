import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pink_diary_calendar/models/daily_record.dart';
import 'package:pink_diary_calendar/services/local_storage_service.dart';
import 'package:pink_diary_calendar/theme/app_colors.dart';
import 'package:pink_diary_calendar/utils/calendar_utils.dart';
import 'package:pink_diary_calendar/widgets/warm_card.dart';
import 'package:pink_diary_calendar/widgets/warm_page_scaffold.dart';

enum _DateRelation { past, today, future }

const double _diaryTextFontSize = 16.0;
const double _diaryTextLineHeight = 1.65;
const double _diaryEditorHorizontalPadding = 22.0;
const double _diaryEditorTopPadding = 18.0;
const double _diaryEditorBottomPadding = 22.0;
const int _thumbnailMaxSize = 400;

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
  static const List<String> _todayPrompts = [
    '今天想留下些什么？',
    '一句话也可以。',
    '把今天轻轻放在这里吧。',
    '不用写很多，几个词也可以。',
    '写给今天的自己一句话吧。',
  ];

  static const List<String> _pastPrompts = [
    '那一天有什么想补上的记忆？',
    '把那天的一点温柔补写下来吧。',
    '迟一点记录，也一样值得被收藏。',
    '有没有一个后来才想起的小瞬间？',
  ];

  static const List<String> _futurePrompts = [
    '未来的这一天，想安排什么？',
    '给未来的自己留一张小纸条吧。',
    '这一天有什么期待？',
    '先把计划轻轻放在这里吧。',
  ];

  final ImagePicker _imagePicker = ImagePicker();

  late final DateTime _date;
  late final String _dateKey;
  late int _promptIndex;

  DailyRecord? _record;
  List<_EditableDiaryBlock> _blocks = [];
  List<AttachmentImage> _attachmentImages = [];
  List<ExpenseEntry> _expenses = [];
  List<PlanEntry> _plans = [];
  bool _isLoading = true;
  bool _isSaving = false;

  _DateRelation get _dateRelation {
    final today = CalendarUtils.dateOnly(DateTime.now());
    if (_date.isBefore(today)) {
      return _DateRelation.past;
    }
    if (_date.isAfter(today)) {
      return _DateRelation.future;
    }
    return _DateRelation.today;
  }

  List<String> get _activePrompts {
    return switch (_dateRelation) {
      _DateRelation.past => _pastPrompts,
      _DateRelation.today => _todayPrompts,
      _DateRelation.future => _futurePrompts,
    };
  }

  String get _inputHint {
    return switch (_dateRelation) {
      _DateRelation.past => '补写那一天想留下的记忆……',
      _DateRelation.today => '写下今天想留下的任何事情……',
      _DateRelation.future => '写下这一天的计划或期待……',
    };
  }

  @override
  void initState() {
    super.initState();
    _date = CalendarUtils.dateOnly(widget.date);
    _dateKey = CalendarUtils.formatDateKey(_date);
    _promptIndex =
        (_date.year + _date.month + _date.day) % _activePrompts.length;
    _loadRecord();
  }

  @override
  void dispose() {
    for (final block in _blocks) {
      block.dispose();
    }
    super.dispose();
  }

  Future<void> _loadRecord() async {
    final record = await widget.storageService.loadDailyRecord(_dateKey);
    if (!mounted) {
      return;
    }

    setState(() {
      _record = record;
      _replaceBlocks(_editableBlocksFromRecord(record));
      _attachmentImages =
          List<AttachmentImage>.from(record?.attachmentImages ?? const []);
      _expenses = List<ExpenseEntry>.from(record?.expenses ?? const []);
      _plans = List<PlanEntry>.from(record?.plans ?? const []);
      _isLoading = false;
    });
  }

  void _replaceBlocks(List<_EditableDiaryBlock> nextBlocks) {
    for (final block in _blocks) {
      block.dispose();
    }
    _blocks = nextBlocks;
  }

  List<_EditableDiaryBlock> _editableBlocksFromRecord(DailyRecord? record) {
    final sourceBlocks = record?.blocks ?? const <DiaryBlock>[];
    if (sourceBlocks.isEmpty) {
      return [_newTextBlock(record?.text ?? '')];
    }

    final blocks = <_EditableDiaryBlock>[];
    for (var i = 0; i < sourceBlocks.length; i++) {
      final block = sourceBlocks[i];
      if (block.isImage) {
        blocks.add(_newImageBlock(
          block.imagePath,
          id: block.id,
          imageWidth: block.imageWidth,
          imageHeight: block.imageHeight,
          thumbnailPath: block.thumbnailPath,
        ));
        // If next block is also an image (or this is the last block),
        // insert an empty text block between them for editing space.
        final nextIsImage = i + 1 < sourceBlocks.length &&
            sourceBlocks[i + 1].isImage;
        final isLastBlock = i == sourceBlocks.length - 1;
        if (nextIsImage || isLastBlock) {
          final spacer = _newTextBlock('');
          spacer.isPlaceholder = true;
          blocks.add(spacer);
        }
      } else {
        blocks.add(_newTextBlock(block.text, id: block.id));
      }
    }

    if (blocks.where((block) => block.type == 'text').isEmpty) {
      blocks.add(_newTextBlock(''));
    }
    return blocks;
  }

  _EditableDiaryBlock _newTextBlock(String text, {String? id}) {
    return _EditableDiaryBlock.text(
      id: id ?? _newEntryId('text-block'),
      controller: TextEditingController(text: text),
      focusNode: FocusNode(),
      createdAt: DateTime.now(),
      isPlaceholder: false,
    );
  }

  _EditableDiaryBlock _newImageBlock(
    String imagePath, {
    String? id,
    double? imageWidth,
    double? imageHeight,
    String? thumbnailPath,
  }) {
    return _EditableDiaryBlock.image(
      id: id ?? _newEntryId('image-block'),
      imagePath: imagePath,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      thumbnailPath: thumbnailPath,
      createdAt: DateTime.now(),
    );
  }

  void _changePrompt() {
    setState(() {
      _promptIndex = (_promptIndex + 1) % _activePrompts.length;
    });
  }

  // ─── Insert Body Image (with free crop) ──────────────────────────

  Future<void> _addBodyImage() async {
    try {
      final pickedImage = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 2400,
      );
      if (pickedImage == null) return;

      if (!mounted) return;

      final croppedFile = await _cropImage(pickedImage.path);
      if (croppedFile == null) return;

      if (!mounted) return;

      final savedPath = await _copyCroppedImageToAppDirectory(croppedFile);
      if (!mounted) return;

      final dimensions = await _readImageDimensions(savedPath);
      if (!mounted) return;

      // Generate thumbnail in background — don't block UI for this
      _generateThumbnail(savedPath).then((thumbPath) {
        if (thumbPath != null && mounted) {
          setState(() {
            _updateBlockThumbnail(savedPath, thumbPath);
          });
        }
      });

      setState(() {
        _insertImageAfterActiveText(
          savedPath,
          imageWidth: dimensions?.width,
          imageHeight: dimensions?.height,
        );
      });
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('图片选择失败，请稍后再试');
    }
  }

  Future<CroppedFile?> _cropImage(String sourcePath) async {
    return ImageCropper().cropImage(
      sourcePath: sourcePath,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: '自由裁剪',
          toolbarColor: const Color(0xFFFFEEF2),
          toolbarWidgetColor: const Color(0xFF594B4F),
          statusBarColor: const Color(0xFFFFEEF2),
          statusBarLight: false,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
          hideBottomControls: true,
          cropFrameColor: const Color(0xFFC96F87),
          cropFrameStrokeWidth: 2,
          showCropGrid: false,
          backgroundColor: const Color(0xFF594B4F),
          activeControlsWidgetColor: const Color(0xFFC96F87),
        ),
        IOSUiSettings(
          title: '自由裁剪',
          hidesNavigationBar: false,
          resetButtonHidden: true,
          aspectRatioLockEnabled: false,
          rotateButtonsHidden: true,
        ),
      ],
    );
  }

  // ─── Add Attachment Image (no crop) ──────────────────────────────

  Future<void> _addAttachmentImage() async {
    try {
      final pickedImage = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 82,
        maxWidth: 1800,
      );
      if (pickedImage == null) return;

      final savedPath = await _copyImageToAppDirectory(pickedImage);
      if (!mounted) return;

      final newId = _newEntryId('attachment');
      setState(() {
        _attachmentImages = [
          ..._attachmentImages,
          AttachmentImage(
            id: newId,
            imagePath: savedPath,
            createdAt: DateTime.now(),
          ),
        ];
      });

      // Generate thumbnail in background
      _generateThumbnail(savedPath).then((thumbPath) {
        if (thumbPath != null && mounted) {
          setState(() {
            _attachmentImages = _attachmentImages.map((img) {
              if (img.id == newId) {
                return AttachmentImage(
                  id: img.id,
                  imagePath: img.imagePath,
                  thumbnailPath: thumbPath,
                  createdAt: img.createdAt,
                );
              }
              return img;
            }).toList();
          });
        }
      });
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('添加附件图片失败，请稍后再试');
    }
  }

  // ─── Image Helpers ──────────────────────────────────────────────

  Future<String> _copyCroppedImageToAppDirectory(CroppedFile croppedFile) async {
    final directory = await getApplicationDocumentsDirectory();
    final imageDirectory = Directory(
      '${directory.path}${Platform.pathSeparator}daily_images',
    );
    if (!await imageDirectory.exists()) {
      await imageDirectory.create(recursive: true);
    }

    final fileName =
        'daily_$_dateKey-crop-${DateTime.now().microsecondsSinceEpoch}.jpg';
    final targetPath =
        '${imageDirectory.path}${Platform.pathSeparator}$fileName';
    await File(croppedFile.path).copy(targetPath);
    return targetPath;
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

  Future<_ImageSize?> _readImageDimensions(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(
        Uint8List.view(bytes.buffer),
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final width = image.width.toDouble();
      final height = image.height.toDouble();
      image.dispose();
      return _ImageSize(width, height);
    } catch (_) {
      return null;
    }
  }

  Future<String?> _generateThumbnail(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) return null;

      final bytes = await file.readAsBytes();
      final codec = await ui.instantiateImageCodec(
        Uint8List.view(bytes.buffer),
        targetWidth: _thumbnailMaxSize,
      );
      final frame = await codec.getNextFrame();
      final image = frame.image;

      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData == null) return null;

      final thumbnailDir = Directory(
        '${file.parent.path}${Platform.pathSeparator}thumbnails',
      );
      if (!await thumbnailDir.exists()) {
        await thumbnailDir.create(recursive: true);
      }

      final thumbName = 'thumb_${DateTime.now().microsecondsSinceEpoch}.png';
      final thumbnailPath =
          '${thumbnailDir.path}${Platform.pathSeparator}$thumbName';

      await File(thumbnailPath).writeAsBytes(
        byteData.buffer.asUint8List(),
      );

      image.dispose();
      return thumbnailPath;
    } catch (_) {
      return null;
    }
  }

  String _fileExtension(String fileName) {
    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == fileName.length - 1) {
      return '.jpg';
    }
    return fileName.substring(dotIndex);
  }

  // ─── Block Management ───────────────────────────────────────────

  void _insertImageAfterActiveText(
    String imagePath, {
    double? imageWidth,
    double? imageHeight,
    String? thumbnailPath,
  }) {
    final activeTextIndex = _activeTextBlockIndex();
    final imageBlock = _newImageBlock(
      imagePath,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      thumbnailPath: thumbnailPath,
    );
    final trailingTextBlock = _newTextBlock('');
    trailingTextBlock.isPlaceholder = true;

    if (activeTextIndex == -1) {
      _blocks = [..._blocks, imageBlock, trailingTextBlock];
      return;
    }

    final activeBlock = _blocks[activeTextIndex];
    final controller = activeBlock.controller;
    final selection = controller?.selection;
    final currentText = controller?.text ?? '';

    if (selection == null || !selection.isValid) {
      _blocks.insertAll(activeTextIndex + 1, [imageBlock, trailingTextBlock]);
      return;
    }

    final start =
        selection.start < selection.end ? selection.start : selection.end;
    final end =
        selection.start < selection.end ? selection.end : selection.start;
    final beforeText = currentText.substring(0, start);
    final afterText = currentText.substring(end);
    controller!.text = beforeText;
    controller.selection = TextSelection.collapsed(offset: beforeText.length);

    final insertedBlocks = <_EditableDiaryBlock>[
      imageBlock,
      afterText.isEmpty ? trailingTextBlock : _newTextBlock(afterText),
    ];
    _blocks.insertAll(activeTextIndex + 1, insertedBlocks);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      insertedBlocks.last.focusNode?.requestFocus();
    });
  }

  int _activeTextBlockIndex() {
    final focusedIndex = _blocks.indexWhere(
      (block) => block.type == 'text' && (block.focusNode?.hasFocus ?? false),
    );
    if (focusedIndex != -1) return focusedIndex;
    return _blocks.lastIndexWhere((block) => block.type == 'text');
  }

  void _removeImageBlock(String id) {
    setState(() {
      final imageIndex = _blocks.indexWhere((block) => block.id == id);
      if (imageIndex == -1) return;

      final removedImage = _blocks.removeAt(imageIndex);
      removedImage.dispose();

      final nextIndex = imageIndex;
      if (nextIndex < _blocks.length) {
        final nextBlock = _blocks[nextIndex];
        final isGeneratedEmptyText = nextBlock.type == 'text' &&
            nextBlock.isPlaceholder &&
            nextBlock.controller?.text.trim().isEmpty == true;
        if (isGeneratedEmptyText) {
          final removedText = _blocks.removeAt(nextIndex);
          removedText.dispose();
        }
      }

      if (_blocks.isEmpty) {
        _blocks = [_newTextBlock('')];
      }
    });
  }

  void _updateBlockThumbnail(String imagePath, String thumbnailPath) {
    for (var i = 0; i < _blocks.length; i++) {
      final block = _blocks[i];
      if (block.type == 'image' && block.imagePath == imagePath) {
        _blocks[i] = _newImageBlock(
          block.imagePath,
          id: block.id,
          imageWidth: block.imageWidth,
          imageHeight: block.imageHeight,
          thumbnailPath: thumbnailPath,
        );
        break;
      }
    }
  }

  void _removeAttachmentImage(String id) {
    setState(() {
      _attachmentImages =
          _attachmentImages.where((img) => img.id != id).toList();
    });
  }

  // ─── Modals ──────────────────────────────────────────────────────

  Future<void> _showExpenseSheet() async {
    final entry = await showModalBottomSheet<ExpenseEntry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _ExpenseInputSheet(onCreateId: () => _newEntryId('expense')),
    );

    if (!mounted || entry == null) return;
    setState(() {
      _expenses = [..._expenses, entry];
    });
  }

  Future<void> _showPlanSheet() async {
    final entry = await showModalBottomSheet<PlanEntry>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PlanInputSheet(onCreateId: () => _newEntryId('plan')),
    );

    if (!mounted || entry == null) return;
    setState(() {
      _plans = [..._plans, entry];
    });
  }

  String _newEntryId(String prefix) {
    return '$prefix-${DateTime.now().microsecondsSinceEpoch}';
  }

  // ─── Save ────────────────────────────────────────────────────────

  Future<void> _saveRecordSilently() async {
    final blocks = _collectDiaryBlocks();
    final hasAnyContent = blocks.isNotEmpty ||
        _attachmentImages.isNotEmpty ||
        _expenses.isNotEmpty ||
        _plans.isNotEmpty;

    if (!hasAnyContent) return;

    FocusScope.of(context).unfocus();
    final record = DailyRecord(
      date: _dateKey,
      text: _combinedText(blocks),
      images: _allImagePaths(blocks),
      blocks: blocks,
      attachmentImages: _attachmentImages,
      expenses: _expenses,
      plans: _plans,
      updatedAt: DateTime.now(),
    );

    try {
      await widget.storageService.saveDailyRecord(record);
    } catch (_) {}
  }

  Future<void> _saveRecord() async {
    FocusScope.of(context).unfocus();
    setState(() => _isSaving = true);

    final blocks = _collectDiaryBlocks();
    final record = DailyRecord(
      date: _dateKey,
      text: _combinedText(blocks),
      images: _allImagePaths(blocks),
      blocks: blocks,
      attachmentImages: _attachmentImages,
      expenses: _expenses,
      plans: _plans,
      updatedAt: DateTime.now(),
    );

    try {
      await widget.storageService.saveDailyRecord(record);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      _showSnackBar('保存失败，请稍后再试');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _showImagePreview(String imagePath) {
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: true,
        pageBuilder: (context, animation, secondaryAnimation) {
          return _FullScreenImageViewer(imagePath: imagePath);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  List<DiaryBlock> _collectDiaryBlocks() {
    final result = <DiaryBlock>[];
    for (var i = 0; i < _blocks.length; i++) {
      final block = _blocks[i];
      if (block.type == 'image') {
        result.add(DiaryBlock(
          id: block.id,
          type: 'image',
          text: '',
          imagePath: block.imagePath,
          thumbnailPath: block.thumbnailPath,
          imageWidth: block.imageWidth,
          imageHeight: block.imageHeight,
          createdAt: block.createdAt,
        ));
        continue;
      }

      final hasText =
          (block.controller?.text.trim().isNotEmpty ?? false);
      final prevIsImage =
          i > 0 && _blocks[i - 1].type == 'image';
      final nextIsImage = i < _blocks.length - 1 &&
          _blocks[i + 1].type == 'image';
      final isBetweenImages = prevIsImage && nextIsImage;
      final isAfterImage =
          prevIsImage && i == _blocks.length - 1;

      if (hasText || isBetweenImages || isAfterImage) {
        result.add(DiaryBlock(
          id: block.id,
          type: 'text',
          text: block.controller?.text ?? '',
          imagePath: '',
          createdAt: block.createdAt,
        ));
      }
    }
    return result;
  }

  String _combinedText(List<DiaryBlock> blocks) {
    return blocks
        .where((block) => block.isText)
        .map((block) => block.text.trim())
        .where((text) => text.isNotEmpty)
        .join('\n\n');
  }

  List<String> _allImagePaths(List<DiaryBlock> blocks) {
    final bodyPaths = blocks
        .where((block) => block.isImage)
        .map((block) => block.imagePath);
    final attachmentPaths =
        _attachmentImages.map((img) => img.imagePath);
    return [...bodyPaths, ...attachmentPaths]
        .where((path) => path.isNotEmpty)
        .toList();
  }

  // ─── Build ───────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final prompts = _activePrompts;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _saveRecordSilently();
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: Colors.transparent,
        body: WarmPageScaffold(
          child: ListView(
            key: const PageStorageKey('day-detail-page'),
            padding: EdgeInsets.fromLTRB(20, 22, 20, 28 + bottomInset),
            children: [
              _DetailHeader(
                date: _date,
                relation: _dateRelation,
                onBack: () async {
                  await _saveRecordSilently();
                  if (mounted) {
                    Navigator.of(context).pop(true);
                  }
                },
              ),
            const SizedBox(height: 18),
            // ── Diary Editor Card ──
            WarmCard(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PromptBar(
                    prompt: prompts[_promptIndex % prompts.length],
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
                  _DiaryBlocksEditor(
                    blocks: _blocks,
                    enabled: !_isLoading && !_isSaving,
                    hintText: _inputHint,
                    onRemoveImage: _removeImageBlock,
                    onPreviewImage: _showImagePreview,
                  ),
                  const SizedBox(height: 16),
                  _QuickActionBar(
                    highlightPlan: _dateRelation == _DateRelation.future,
                    onAddBodyImage: _addBodyImage,
                    onAddAttachmentImage: _addAttachmentImage,
                    onAddExpense: _showExpenseSheet,
                    onAddPlan: _showPlanSheet,
                  ),
                ],
              ),
            ),
            // ── Expenses ──
            if (_expenses.isNotEmpty) ...[
              const SizedBox(height: 18),
              _ExpenseSection(
                expenses: _expenses,
                onRemove: (id) {
                  setState(() {
                    _expenses =
                        _expenses.where((entry) => entry.id != id).toList();
                  });
                },
              ),
            ],
            // ── Plans ──
            if (_plans.isNotEmpty) ...[
              const SizedBox(height: 18),
              _PlanSection(
                plans: _plans,
                onRemove: (id) {
                  setState(() {
                    _plans =
                        _plans.where((entry) => entry.id != id).toList();
                  });
                },
              ),
            ],
            // ── Attachment Images ──
            if (_attachmentImages.isNotEmpty) ...[
              const SizedBox(height: 18),
              _AttachmentImageSection(
                images: _attachmentImages,
                onRemove: _removeAttachmentImage,
                onPreview: _showImagePreview,
              ),
            ],
            // ── Save Button ──
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
    ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Data classes
// ═══════════════════════════════════════════════════════════════════

class _ImageSize {
  const _ImageSize(this.width, this.height);
  final double width;
  final double height;
}

class _EditableDiaryBlock {
  _EditableDiaryBlock.text({
    required this.id,
    required this.controller,
    required this.focusNode,
    required this.createdAt,
    required this.isPlaceholder,
  })  : type = 'text',
        imagePath = '',
        thumbnailPath = null,
        imageWidth = null,
        imageHeight = null;

  _EditableDiaryBlock.image({
    required this.id,
    required this.imagePath,
    required this.createdAt,
    this.thumbnailPath,
    this.imageWidth,
    this.imageHeight,
  })  : type = 'image',
        controller = null,
        focusNode = null,
        isPlaceholder = false;

  final String id;
  final String type;
  final String imagePath;
  final String? thumbnailPath;
  final double? imageWidth;
  final double? imageHeight;
  final DateTime createdAt;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  bool isPlaceholder;

  void dispose() {
    focusNode?.dispose();
    controller?.dispose();
  }
}

// ═══════════════════════════════════════════════════════════════════
// Diary Blocks Editor
// ═══════════════════════════════════════════════════════════════════

class _DiaryBlocksEditor extends StatelessWidget {
  const _DiaryBlocksEditor({
    required this.blocks,
    required this.enabled,
    required this.hintText,
    required this.onRemoveImage,
    required this.onPreviewImage,
  });

  final List<_EditableDiaryBlock> blocks;
  final bool enabled;
  final String hintText;
  final ValueChanged<String> onRemoveImage;
  final ValueChanged<String> onPreviewImage;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cream.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.line.withValues(alpha: 0.8)),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final contentWidth =
              constraints.maxWidth - _diaryEditorHorizontalPadding * 2;
          return Padding(
            padding: const EdgeInsets.fromLTRB(
              _diaryEditorHorizontalPadding,
              _diaryEditorTopPadding,
              _diaryEditorHorizontalPadding,
              _diaryEditorBottomPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < blocks.length; index++)
                  _DiaryBlockView(
                    key: ValueKey(blocks[index].id),
                    block: blocks[index],
                    enabled: enabled,
                    hintText: _hintForBlock(index),
                    minLines: _minLinesForBlock(index),
                    contentWidth: contentWidth,
                    onRemoveImage: () => onRemoveImage(blocks[index].id),
                    onPreviewImage: () =>
                        onPreviewImage(blocks[index].imagePath),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _hintForBlock(int index) {
    if (index == 0) return hintText;
    return '继续写一点……';
  }

  int _minLinesForBlock(int index) {
    if (blocks.length == 1) return 14;
    final block = blocks[index];
    if (block.type == 'text' &&
        (block.controller?.text.isNotEmpty ?? false)) {
      return 1;
    }
    return index == 0 ? 4 : 2;
  }
}

// ═══════════════════════════════════════════════════════════════════
// Block View
// ═══════════════════════════════════════════════════════════════════

class _DiaryBlockView extends StatelessWidget {
  const _DiaryBlockView({
    required this.block,
    required this.enabled,
    required this.hintText,
    required this.minLines,
    required this.contentWidth,
    required this.onRemoveImage,
    required this.onPreviewImage,
    super.key,
  });

  final _EditableDiaryBlock block;
  final bool enabled;
  final String hintText;
  final int minLines;
  final double contentWidth;
  final VoidCallback onRemoveImage;
  final VoidCallback onPreviewImage;

  @override
  Widget build(BuildContext context) {
    if (block.type == 'image') {
      return _InlineImageBlock(
        imagePath: block.imagePath,
        thumbnailPath: block.thumbnailPath,
        maxWidth: contentWidth,
        imageWidth: block.imageWidth,
        imageHeight: block.imageHeight,
        onTap: onPreviewImage,
        onRemove: onRemoveImage,
      );
    }

    return _DiaryTextBlockField(
      controller: block.controller!,
      focusNode: block.focusNode!,
      enabled: enabled,
      hintText: hintText,
      minLines: minLines,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Text Block Field (clean, no lines)
// ═══════════════════════════════════════════════════════════════════

class _DiaryTextBlockField extends StatelessWidget {
  const _DiaryTextBlockField({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.hintText,
    required this.minLines,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final String hintText;
  final int minLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      minLines: minLines,
      maxLines: null,
      keyboardType: TextInputType.multiline,
      textAlignVertical: TextAlignVertical.top,
      style: const TextStyle(
        color: AppColors.ink,
        fontSize: _diaryTextFontSize,
        height: _diaryTextLineHeight,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle:
            TextStyle(color: AppColors.muted.withValues(alpha: 0.72)),
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
      ),
      strutStyle: const StrutStyle(
        fontSize: _diaryTextFontSize,
        height: _diaryTextLineHeight,
        forceStrutHeight: true,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Inline Image Block (body image)
// ═══════════════════════════════════════════════════════════════════

class _InlineImageBlock extends StatefulWidget {
  const _InlineImageBlock({
    required this.imagePath,
    required this.thumbnailPath,
    required this.maxWidth,
    required this.imageWidth,
    required this.imageHeight,
    required this.onTap,
    required this.onRemove,
  });

  final String imagePath;
  final String? thumbnailPath;
  final double maxWidth;
  final double? imageWidth;
  final double? imageHeight;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  State<_InlineImageBlock> createState() => _InlineImageBlockState();
}

class _InlineImageBlockState extends State<_InlineImageBlock> {
  late String _displayPath;

  @override
  void initState() {
    super.initState();
    _resolveDisplayPath();
  }

  @override
  void didUpdateWidget(covariant _InlineImageBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imagePath != widget.imagePath ||
        oldWidget.thumbnailPath != widget.thumbnailPath) {
      _resolveDisplayPath();
    }
  }

  void _resolveDisplayPath() {
    if (widget.thumbnailPath != null &&
        widget.thumbnailPath!.isNotEmpty &&
        File(widget.thumbnailPath!).existsSync()) {
      _displayPath = widget.thumbnailPath!;
    } else {
      _displayPath = widget.imagePath;
    }
  }

  @override
  Widget build(BuildContext context) {
    final safeWidth =
        widget.maxWidth > 0 ? widget.maxWidth : 260.0;
    final displayHeight = (widget.imageWidth != null &&
            widget.imageHeight != null &&
            widget.imageWidth! > 0)
        ? safeWidth * widget.imageHeight! / widget.imageWidth!
        : safeWidth * 3 / 4;

    final devicePixelRatio =
        MediaQuery.devicePixelRatioOf(context);
    final cacheWidth = (safeWidth * devicePixelRatio).round();
    final cacheHeight =
        (displayHeight * devicePixelRatio).round();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: GestureDetector(
        onTap: widget.onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              SizedBox(
                width: safeWidth,
                height: displayHeight,
                child: RepaintBoundary(
                  child: Image.file(
                    File(_displayPath),
                    fit: BoxFit.cover,
                    width: safeWidth,
                    height: displayHeight,
                    cacheWidth: cacheWidth > 0 ? cacheWidth : null,
                    cacheHeight:
                        cacheHeight > 0 ? cacheHeight : null,
                    filterQuality: FilterQuality.medium,
                    errorBuilder:
                        (context, error, stackTrace) {
                      return Container(
                        color: AppColors.cream
                            .withValues(alpha: 0.8),
                        child: Center(
                          child: Text(
                            '图片加载失败',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                    color: AppColors.muted),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: _MiniDeleteButton(
                    onTap: widget.onRemove),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Full Screen Image Viewer
// ═══════════════════════════════════════════════════════════════════

class _FullScreenImageViewer extends StatelessWidget {
  const _FullScreenImageViewer({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).maybePop(),
      child: ColoredBox(
        color: Colors.black,
        child: SafeArea(
          child: Center(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Image.file(
                File(imagePath),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Text(
                    '图片暂时无法显示',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.white),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Attachment Image Section
// ═══════════════════════════════════════════════════════════════════

class _AttachmentImageSection extends StatelessWidget {
  const _AttachmentImageSection({
    required this.images,
    required this.onRemove,
    required this.onPreview,
  });

  final List<AttachmentImage> images;
  final ValueChanged<String> onRemove;
  final ValueChanged<String> onPreview;

  @override
  Widget build(BuildContext context) {
    return WarmCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.photo_library_outlined,
            title: '附件图片',
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: images.length,
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 1,
            ),
            itemBuilder: (context, index) {
              final image = images[index];
              return _AttachmentImageTile(
                image: image,
                onTap: () => onPreview(image.imagePath),
                onRemove: () => onRemove(image.id),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AttachmentImageTile extends StatefulWidget {
  const _AttachmentImageTile({
    required this.image,
    required this.onTap,
    required this.onRemove,
  });

  final AttachmentImage image;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  State<_AttachmentImageTile> createState() =>
      _AttachmentImageTileState();
}

class _AttachmentImageTileState extends State<_AttachmentImageTile> {
  late String _displayPath;

  @override
  void initState() {
    super.initState();
    _resolveDisplayPath();
  }

  @override
  void didUpdateWidget(covariant _AttachmentImageTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.image.imagePath != widget.image.imagePath ||
        oldWidget.image.thumbnailPath !=
            widget.image.thumbnailPath) {
      _resolveDisplayPath();
    }
  }

  void _resolveDisplayPath() {
    if (widget.image.thumbnailPath != null &&
        widget.image.thumbnailPath!.isNotEmpty &&
        File(widget.image.thumbnailPath!).existsSync()) {
      _displayPath = widget.image.thumbnailPath!;
    } else {
      _displayPath = widget.image.imagePath;
    }
  }

  @override
  Widget build(BuildContext context) {
    final devicePixelRatio =
        MediaQuery.devicePixelRatioOf(context);
    final cacheSize = (160 * devicePixelRatio).round();

    return GestureDetector(
      onTap: widget.onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Positioned.fill(
              child: RepaintBoundary(
                child: Image.file(
                  File(_displayPath),
                  fit: BoxFit.cover,
                  cacheWidth: cacheSize,
                  cacheHeight: cacheSize,
                  filterQuality: FilterQuality.medium,
                  errorBuilder:
                      (context, error, stackTrace) {
                    return Container(
                      color: AppColors.cream
                          .withValues(alpha: 0.8),
                      child: const Center(
                        child: Icon(
                            Icons.broken_image_outlined,
                            color: AppColors.muted,
                            size: 28),
                      ),
                    );
                  },
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: _MiniDeleteButton(
                  onTap: widget.onRemove),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Expense Input Sheet
// ═══════════════════════════════════════════════════════════════════

class _ExpenseInputSheet extends StatefulWidget {
  const _ExpenseInputSheet({required this.onCreateId});

  final String Function() onCreateId;

  @override
  State<_ExpenseInputSheet> createState() => _ExpenseInputSheetState();
}

class _ExpenseInputSheetState extends State<_ExpenseInputSheet> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  String _selectedType = 'expense';
  String? _errorText;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _errorText = '请输入正确的金额');
      return;
    }

    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(
      ExpenseEntry(
        id: widget.onCreateId(),
        amount: amount,
        note: _noteController.text.trim(),
        type: _selectedType,
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _WarmBottomSheet(
      title: '记一笔',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _TypeChoice(
                  label: '支出',
                  selected: _selectedType == 'expense',
                  onTap: () => setState(() => _selectedType = 'expense'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TypeChoice(
                  label: '收入',
                  selected: _selectedType == 'income',
                  onTap: () => setState(() => _selectedType = 'income'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _amountController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) {
              if (_errorText != null) {
                setState(() => _errorText = null);
              }
            },
            decoration: _softInputDecoration('金额'),
          ),
          if (_errorText != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _errorText!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.roseDeep,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            decoration: _softInputDecoration('说明，可以留空'),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
                onPressed: _submit, child: const Text('确定')),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Plan Input Sheet
// ═══════════════════════════════════════════════════════════════════

class _PlanInputSheet extends StatefulWidget {
  const _PlanInputSheet({required this.onCreateId});

  final String Function() onCreateId;

  @override
  State<_PlanInputSheet> createState() => _PlanInputSheetState();
}

class _PlanInputSheetState extends State<_PlanInputSheet> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _textController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      setState(() => _errorText = '写下计划内容吧');
      return;
    }

    FocusScope.of(context).unfocus();
    Navigator.of(context).pop(
      PlanEntry(
        id: widget.onCreateId(),
        text: text,
        note: _noteController.text.trim(),
        createdAt: DateTime.now(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _WarmBottomSheet(
      title: '添加计划',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _textController,
            minLines: 3,
            maxLines: 5,
            onChanged: (_) {
              if (_errorText != null) {
                setState(() => _errorText = null);
              }
            },
            decoration: _softInputDecoration('计划内容，例如：和朋友出去玩'),
          ),
          if (_errorText != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _errorText!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.roseDeep,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          TextField(
            controller: _noteController,
            minLines: 2,
            maxLines: 4,
            decoration: _softInputDecoration('备注，可以留空'),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
                onPressed: _submit, child: const Text('确定')),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Detail Header
// ═══════════════════════════════════════════════════════════════════

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({
    required this.date,
    required this.relation,
    required this.onBack,
  });

  final DateTime date;
  final _DateRelation relation;
  final VoidCallback onBack;

  String get _eyebrow {
    return switch (relation) {
      _DateRelation.past => '补记这一页',
      _DateRelation.today => '今日记录',
      _DateRelation.future => '未来计划',
    };
  }

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
                color: AppColors.milk.withValues(alpha: 0.9),
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.8)),
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
                _eyebrow,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.roseDeep,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                CalendarUtils.formatFullDate(date),
                style:
                    textTheme.headlineSmall?.copyWith(color: AppColors.ink),
              ),
              const SizedBox(height: 5),
              Text(
                CalendarUtils.weekdayName(date),
                style: textTheme.titleMedium?.copyWith(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Prompt Bar
// ═══════════════════════════════════════════════════════════════════

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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.ink,
                    fontSize: 15,
                    height: 1.35,
                  ),
            ),
          ),
          TextButton.icon(
            onPressed: onChangePrompt,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('换一句'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.roseDeep,
              visualDensity: VisualDensity.compact,
              textStyle:
                  const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Quick Action Bar
// ═══════════════════════════════════════════════════════════════════

class _QuickActionBar extends StatelessWidget {
  const _QuickActionBar({
    required this.highlightPlan,
    required this.onAddBodyImage,
    required this.onAddAttachmentImage,
    required this.onAddExpense,
    required this.onAddPlan,
  });

  final bool highlightPlan;
  final VoidCallback onAddBodyImage;
  final VoidCallback onAddAttachmentImage;
  final VoidCallback onAddExpense;
  final VoidCallback onAddPlan;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _QuickActionButton(
          icon: Icons.image_outlined,
          label: '插入正文图片',
          onTap: onAddBodyImage,
        ),
        _QuickActionButton(
          icon: Icons.attach_file_rounded,
          label: '添加附件图片',
          onTap: onAddAttachmentImage,
        ),
        _QuickActionButton(
          icon: Icons.receipt_long_outlined,
          label: '记一笔',
          onTap: onAddExpense,
        ),
        _QuickActionButton(
          icon: Icons.event_note_outlined,
          label: '添加计划',
          highlighted: highlightPlan,
          onTap: onAddPlan,
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
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final foregroundColor =
        highlighted ? AppColors.ink : AppColors.roseDeep;

    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: foregroundColor,
        backgroundColor: highlighted
            ? AppColors.roseDeep
            : AppColors.milk.withValues(alpha: 0.74),
        side: BorderSide(
          color: highlighted
              ? AppColors.roseDeep
              : AppColors.line.withValues(alpha: 0.85),
        ),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999)),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        textStyle: const TextStyle(
            fontSize: 13, fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Expense Section
// ═══════════════════════════════════════════════════════════════════

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
          const _SectionTitle(
              icon: Icons.receipt_long_rounded, title: '今日小账'),
          const SizedBox(height: 12),
          ...expenses.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child:
                  _ExpenseTile(entry: entry, onRemove: onRemove),
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
    final color =
        entry.isIncome ? AppColors.lavenderDeep : AppColors.roseDeep;
    final typeLabel = entry.isIncome ? '记账 · 收入' : '记账 · 支出';

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: AppColors.cream.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: AppColors.line.withValues(alpha: 0.8)),
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
            child: Icon(Icons.payments_outlined,
                color: color, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  typeLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 3),
                Text(
                  entry.displayNote,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                        color: AppColors.ink,
                        fontSize: 15,
                      ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '金额',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(
                      color: AppColors.muted,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 3),
              Text(
                '$sign$amountText 元',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
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

// ═══════════════════════════════════════════════════════════════════
// Plan Section
// ═══════════════════════════════════════════════════════════════════

class _PlanSection extends StatelessWidget {
  const _PlanSection({required this.plans, required this.onRemove});

  final List<PlanEntry> plans;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return WarmCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
              icon: Icons.event_note_rounded, title: '计划'),
          const SizedBox(height: 12),
          ...plans.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child:
                  _PlanTile(entry: entry, onRemove: onRemove),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({required this.entry, required this.onRemove});

  final PlanEntry entry;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 14, 10, 14),
      decoration: BoxDecoration(
        color: AppColors.lavender.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.8)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.event_available_rounded,
            color: AppColors.lavenderDeep,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '计划：${entry.text}',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(
                        color: AppColors.ink,
                        height: 1.5,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                if (entry.note.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    '备注：${entry.note}',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(
                          color: AppColors.muted,
                          height: 1.45,
                        ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          _MiniDeleteButton(onTap: () => onRemove(entry.id)),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// Shared Widgets
// ═══════════════════════════════════════════════════════════════════

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
          child: Icon(Icons.close_rounded,
              color: AppColors.roseDeep, size: 17),
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
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(color: AppColors.ink, fontSize: 14),
        ),
      ),
    );
  }
}

class _WarmBottomSheet extends StatelessWidget {
  const _WarmBottomSheet({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
        decoration: const BoxDecoration(
          color: AppColors.milk,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
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
                Text(title,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

InputDecoration _softInputDecoration(String hintText) {
  return InputDecoration(
    hintText: hintText,
    hintStyle:
        TextStyle(color: AppColors.muted.withValues(alpha: 0.72)),
    filled: true,
    fillColor: AppColors.cream.withValues(alpha: 0.72),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide:
          BorderSide(color: AppColors.line.withValues(alpha: 0.8)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide:
          BorderSide(color: AppColors.line.withValues(alpha: 0.8)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide:
          const BorderSide(color: AppColors.roseDeep, width: 1.2),
    ),
    contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );
}
