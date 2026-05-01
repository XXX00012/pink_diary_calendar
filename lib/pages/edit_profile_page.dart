import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pink_diary_calendar/models/user_profile.dart';
import 'package:pink_diary_calendar/services/local_storage_service.dart';
import 'package:pink_diary_calendar/theme/app_colors.dart';
import 'package:pink_diary_calendar/utils/profile_theme_utils.dart';
import 'package:pink_diary_calendar/widgets/warm_card.dart';
import 'package:pink_diary_calendar/widgets/warm_page_scaffold.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({
    required this.profile,
    this.storageService = const LocalStorageService(),
    super.key,
  });

  final UserProfile profile;
  final LocalStorageService storageService;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _signatureController = TextEditingController();

  late String _avatarPath;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _avatarPath = widget.profile.avatarPath;
    _nicknameController.text = widget.profile.nickname;
    _signatureController.text = widget.profile.signature;
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    try {
      final pickedImage = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 88,
      );
      if (pickedImage == null) {
        return;
      }

      final savedPath = await _copyAvatarToAppDirectory(pickedImage);
      if (!mounted) {
        return;
      }
      setState(() => _avatarPath = savedPath);
    } catch (_) {
      if (!mounted) {
        return;
      }
      _showTip('头像选择失败，请稍后再试');
    }
  }

  Future<String> _copyAvatarToAppDirectory(XFile pickedImage) async {
    final directory = await getApplicationDocumentsDirectory();
    final avatarDirectory = Directory(
      '${directory.path}${Platform.pathSeparator}profile_avatar',
    );
    if (!await avatarDirectory.exists()) {
      await avatarDirectory.create(recursive: true);
    }

    final extension = _fileExtension(pickedImage.name);
    final targetPath =
        '${avatarDirectory.path}${Platform.pathSeparator}avatar-${DateTime.now().microsecondsSinceEpoch}$extension';
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

  Future<void> _save() async {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) {
      _showTip('给自己取个名字吧');
      return;
    }

    setState(() => _isSaving = true);
    final profile = widget.profile.copyWith(
      avatarPath: _avatarPath,
      nickname: nickname,
      signature: _signatureController.text.trim(),
      updatedAt: DateTime.now(),
    );

    try {
      await widget.storageService.saveUserProfile(profile);
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

  void _showTip(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = ProfileThemeUtils.byKey(widget.profile.themeKey);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return _ProfileSettingScaffold(
      title: '编辑我的手账封面',
      subtitle: '让这里更像你自己',
      paddingBottom: 28 + bottomInset,
      child: Column(
        children: [
          WarmCard(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickAvatar,
                  child: _EditableAvatar(
                    avatarPath: _avatarPath,
                    primaryColor: theme.primary,
                    secondaryColor: theme.secondary,
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _nicknameController,
                  decoration: _inputDecoration('给自己取个温柔的名字'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _signatureController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: _inputDecoration('写一句想对自己说的话'),
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
                _isSaving ? Icons.hourglass_empty_rounded : Icons.save_rounded,
              ),
              label: Text(_isSaving ? '正在保存' : '保存封面'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableAvatar extends StatelessWidget {
  const _EditableAvatar({
    required this.avatarPath,
    required this.primaryColor,
    required this.secondaryColor,
  });

  final String avatarPath;
  final Color primaryColor;
  final Color secondaryColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 104,
          height: 104,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [secondaryColor, primaryColor.withValues(alpha: 0.75)],
            ),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
          ),
          clipBehavior: Clip.antiAlias,
          child: avatarPath.isEmpty
              ? const Icon(
                  Icons.local_florist_rounded,
                  color: Colors.white,
                  size: 42,
                )
              : Image.file(
                  File(avatarPath),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.local_florist_rounded,
                      color: Colors.white,
                      size: 42,
                    );
                  },
                ),
        ),
        Positioned(
          right: -2,
          bottom: 3,
          child: Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: AppColors.roseDeep,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.photo_camera_rounded,
              color: Colors.white,
              size: 17,
            ),
          ),
        ),
      ],
    );
  }
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

class _ProfileSettingScaffold extends StatelessWidget {
  const _ProfileSettingScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
    this.paddingBottom = 28,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final double paddingBottom;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.transparent,
      body: WarmPageScaffold(
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, 22, 20, paddingBottom),
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
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.muted,
                        ),
                      ),
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
