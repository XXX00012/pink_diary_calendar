import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pink_diary_calendar/models/app_settings.dart';
import 'package:pink_diary_calendar/services/local_storage_service.dart';
import 'package:pink_diary_calendar/services/notification_service.dart';
import 'package:pink_diary_calendar/theme/app_colors.dart';
import 'package:pink_diary_calendar/theme/theme_controller.dart';
import 'package:pink_diary_calendar/utils/profile_theme_utils.dart';
import 'package:pink_diary_calendar/widgets/warm_card.dart';
import 'package:pink_diary_calendar/widgets/warm_page_scaffold.dart';

class ThemeSettingsPage extends StatefulWidget {
  const ThemeSettingsPage({
    required this.currentThemeKey,
    this.storageService = const LocalStorageService(),
    super.key,
  });

  final String currentThemeKey;
  final LocalStorageService storageService;

  @override
  State<ThemeSettingsPage> createState() => _ThemeSettingsPageState();
}

class _ThemeSettingsPageState extends State<ThemeSettingsPage> {
  late String _selectedThemeKey;

  @override
  void initState() {
    super.initState();
    _selectedThemeKey = widget.currentThemeKey;
  }

  Future<void> _selectTheme(String themeKey) async {
    setState(() => _selectedThemeKey = themeKey);
    try {
      await AppThemeController.instance.setThemeKey(themeKey);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('主题已经轻轻换好啦')));
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('保存失败，请稍后再试')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProfileSettingScaffold(
      title: '主题装扮',
      subtitle: '给你的手账封面换一种温柔心情',
      child: Column(
        children: ProfileThemeUtils.options.map((theme) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ThemeOptionCard(
              theme: theme,
              selected: _selectedThemeKey == theme.key,
              onTap: () => _selectTheme(theme.key),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class PrivacySettingsPage extends StatefulWidget {
  const PrivacySettingsPage({
    required this.settings,
    this.storageService = const LocalStorageService(),
    super.key,
  });

  final AppSettings settings;
  final LocalStorageService storageService;

  @override
  State<PrivacySettingsPage> createState() => _PrivacySettingsPageState();
}

class _PrivacySettingsPageState extends State<PrivacySettingsPage> {
  final TextEditingController _hintController = TextEditingController();

  late bool _enabled;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _enabled = widget.settings.privacyLockEnabled;
    _hintController.text = widget.settings.passwordHint;
  }

  @override
  void dispose() {
    _hintController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final settings = widget.settings.copyWith(
      privacyLockEnabled: _enabled,
      passwordHint: _hintController.text.trim(),
      updatedAt: DateTime.now(),
    );

    try {
      await widget.storageService.saveAppSettings(settings);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() => _isSaving = false);
      _showSaveFailed(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProfileSettingScaffold(
      title: '隐私密码',
      subtitle: '先保存隐私偏好，完整保护会在后续接入',
      child: Column(
        children: [
          WarmCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  value: _enabled,
                  onChanged: (value) => setState(() => _enabled = value),
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: AppColors.roseDeep,
                  title: Text(
                    '开启隐私密码',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    '开启后，后续版本可用于保护你的私人记录',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _hintController,
                  decoration: softInputDecoration('密码提示语，可选'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _SaveButton(isSaving: _isSaving, label: '保存隐私设置', onPressed: _save),
        ],
      ),
    );
  }
}

class ReminderSettingsPage extends StatefulWidget {
  const ReminderSettingsPage({
    required this.settings,
    this.storageService = const LocalStorageService(),
    super.key,
  });

  final AppSettings settings;
  final LocalStorageService storageService;

  @override
  State<ReminderSettingsPage> createState() => _ReminderSettingsPageState();
}

class _ReminderSettingsPageState extends State<ReminderSettingsPage> {
  final TextEditingController _timeController = TextEditingController();
  final NotificationService _notificationService = NotificationService.instance;

  late bool _enabled;
  late bool _permissionGranted;
  bool _isSaving = false;
  bool _isRequestingPermission = false;

  @override
  void initState() {
    super.initState();
    _enabled = widget.settings.anniversaryNotificationEnabled;
    _permissionGranted = widget.settings.notificationPermissionGranted;
    _timeController.text = widget.settings.anniversaryReminderTime;
    _refreshPermissionStatus();
  }

  @override
  void dispose() {
    _timeController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final parts = _timeController.text.split(':');
    final initialHour = int.tryParse(parts.first) ?? 9;
    final initialMinute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initialHour, minute: initialMinute),
      helpText: '选择纪念日提醒时间',
      cancelText: '取消',
      confirmText: '确定',
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _timeController.text =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    });
  }

  Future<void> _refreshPermissionStatus() async {
    try {
      final granted = await _notificationService.areNotificationsEnabled();
      if (!mounted) {
        return;
      }

      setState(() {
        _permissionGranted = granted;
        if (!granted) {
          _enabled = false;
        }
      });
    } catch (error, stackTrace) {
      debugPrint('Refresh notification permission failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) {
        return;
      }
      setState(() {
        _permissionGranted = false;
        _enabled = false;
      });
    }
  }

  Future<void> _handleEnabledChanged(bool value) async {
    if (!value) {
      setState(() {
        _enabled = false;
      });
      await _persistSettings(popWhenDone: false, enabled: false);
      return;
    }

    setState(() => _isRequestingPermission = true);
    try {
      final granted = await _notificationService.requestPermission();
      if (!mounted) {
        return;
      }

      setState(() {
        _enabled = granted;
        _permissionGranted = granted;
      });

      if (!granted) {
        await _persistSettings(popWhenDone: false, enabled: false);
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('系统通知权限未开启，暂时无法提醒重要日子')));
      }
    } catch (error, stackTrace) {
      debugPrint('Request notification permission failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) {
        return;
      }
      setState(() {
        _enabled = false;
        _permissionGranted = false;
      });
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('系统通知权限请求失败：${_friendlyError(error)}')),
        );
    } finally {
      if (mounted) {
        setState(() => _isRequestingPermission = false);
      }
    }
  }

  Future<void> _save() async {
    await _persistSettings(popWhenDone: true);
  }

  Future<void> _persistSettings({
    required bool popWhenDone,
    bool? enabled,
  }) async {
    setState(() => _isSaving = true);
    var nextEnabled = enabled ?? _enabled;
    var nextPermissionGranted = _permissionGranted;

    if (nextEnabled && !nextPermissionGranted) {
      nextPermissionGranted = await _notificationService.requestPermission();
      if (!mounted) {
        return;
      }
      if (!nextPermissionGranted) {
        nextEnabled = false;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('系统通知权限未开启，暂时无法提醒重要日子')));
      }
    }

    final reminderTime = _normalizedReminderTime();
    final settings = widget.settings.copyWith(
      anniversaryNotificationEnabled: nextEnabled,
      anniversaryReminderTime: reminderTime,
      notificationPermissionGranted: nextPermissionGranted,
      updatedAt: DateTime.now(),
    );

    try {
      await widget.storageService.saveAppSettings(settings);
    } catch (error, stackTrace) {
      debugPrint('Save notification settings failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) {
        return;
      }
      setState(() => _isSaving = false);
      _showMessage('保存通知设置失败：${_friendlyError(error)}');
      return;
    }

    String? scheduleWarning;
    try {
      if (nextEnabled && nextPermissionGranted) {
        final scheduled = await _notificationService
            .rescheduleAnniversaryNotifications(
              storageService: widget.storageService,
            );
        if (!scheduled) {
          nextEnabled = false;
          final disabledSettings = settings.copyWith(
            anniversaryNotificationEnabled: false,
            updatedAt: DateTime.now(),
          );
          await widget.storageService.saveAppSettings(disabledSettings);
          scheduleWarning = '通知设置已保存，但当前手机暂不支持定时提醒，请检查系统通知/闹钟权限。';
        }
      } else {
        await _notificationService.cancelAllAnniversaryNotifications();
      }
    } catch (error, stackTrace) {
      debugPrint('Apply notification schedule failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      nextEnabled = false;
      try {
        await widget.storageService.saveAppSettings(
          settings.copyWith(
            anniversaryNotificationEnabled: false,
            updatedAt: DateTime.now(),
          ),
        );
      } catch (saveError, saveStackTrace) {
        debugPrint('Disable notification settings failed: $saveError');
        debugPrintStack(stackTrace: saveStackTrace);
      }
      scheduleWarning = '通知设置已保存，但当前手机暂不支持定时提醒，请检查系统通知/闹钟权限。';
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _enabled = nextEnabled;
      _permissionGranted = nextPermissionGranted;
      _timeController.text = reminderTime;
      _isSaving = false;
    });

    _showMessage(scheduleWarning ?? '通知设置已保存');
    if (popWhenDone && scheduleWarning == null) {
      await Future<void>.delayed(const Duration(milliseconds: 450));
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    }
  }

  Future<void> _sendTestNotification() async {
    try {
      final granted = await _notificationService.areNotificationsEnabled();
      if (!mounted) {
        return;
      }

      if (!granted) {
        setState(() => _permissionGranted = false);
        _showMessage('请先开启系统通知权限');
        return;
      }

      final sent = await _notificationService.scheduleTestNotification();
      if (!mounted) {
        return;
      }
      if (sent) {
        _showMessage('测试通知已发送');
      } else {
        setState(() => _enabled = false);
        _showMessage('测试通知发送失败：当前手机暂不支持通知，请检查系统通知权限。');
      }
    } catch (error, stackTrace) {
      debugPrint('Send test notification failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) {
        return;
      }
      _showMessage('测试通知发送失败：${_friendlyError(error)}');
    }
  }

  String _normalizedReminderTime() {
    final parts = _timeController.text.trim().split(':');
    final hour = (int.tryParse(parts.first) ?? 9).clamp(0, 23).toInt();
    final minute = (parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0)
        .clamp(0, 59)
        .toInt();
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  String _friendlyError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    if (message.isEmpty) {
      return '未知错误';
    }
    return message.length > 80 ? '${message.substring(0, 80)}…' : message;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return ProfileSettingScaffold(
      title: '通知设置',
      subtitle: '只提醒重要日子，不打扰你的自由记录',
      child: Column(
        children: [
          WarmCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '开启后，暖桃日记只会在你设置的生日、纪念日和重要日期前提醒你，不会催你每天写日记。',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.ink,
                    height: 1.55,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                SwitchListTile(
                  value: _enabled,
                  onChanged: _isRequestingPermission
                      ? null
                      : _handleEnabledChanged,
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: AppColors.roseDeep,
                  title: Text(
                    '开启纪念日提醒',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    '生日、纪念日和重要日期会按你设置的时间提醒',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _timeController,
                  readOnly: true,
                  onTap: _pickTime,
                  decoration: softInputDecoration('提醒时间，例如 09:00'),
                ),
                const SizedBox(height: 14),
                _PermissionStatusRow(granted: _permissionGranted),
                if (!_enabled) ...[
                  const SizedBox(height: 10),
                  Text(
                    '开启后，系统会在重要日子到来前提醒你。',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.muted),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _sendTestNotification,
              icon: const Icon(Icons.notifications_active_outlined),
              label: const Text('发送测试通知'),
            ),
          ),
          const SizedBox(height: 12),
          _SaveButton(isSaving: _isSaving, label: '保存通知设置', onPressed: _save),
        ],
      ),
    );
  }
}

class _PermissionStatusRow extends StatelessWidget {
  const _PermissionStatusRow({required this.granted});

  final bool granted;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cream.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.line.withValues(alpha: 0.75)),
      ),
      child: Row(
        children: [
          Icon(
            granted
                ? Icons.notifications_active_outlined
                : Icons.notifications_off_outlined,
            color: granted ? const Color(0xFF6AA978) : AppColors.muted,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              granted ? '系统通知权限：已允许' : '系统通知权限：未开启',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DataExportPage extends StatefulWidget {
  const DataExportPage({
    this.storageService = const LocalStorageService(),
    super.key,
  });

  final LocalStorageService storageService;

  @override
  State<DataExportPage> createState() => _DataExportPageState();
}

class _DataExportPageState extends State<DataExportPage> {
  bool _isCopying = false;

  Future<void> _copyBackupJson() async {
    setState(() => _isCopying = true);
    try {
      final backupJson = await widget.storageService.exportBackupJson();
      await Clipboard.setData(ClipboardData(text: backupJson));
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('备份内容已复制，可以保存到备忘录或发送到新手机')),
        );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('导出失败，请稍后再试')));
    } finally {
      if (mounted) {
        setState(() => _isCopying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ProfileSettingScaffold(
      title: '本地备份 / 导出',
      subtitle: '导出本机日记和纪念日，方便换手机备份',
      child: Column(
        children: [
          WarmCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('会复制一份 JSON 备份文本，包含日记记录、纪念日、个人资料和设置。'),
                SizedBox(height: 14),
                _FutureFeatureTile(
                  icon: Icons.edit_calendar_rounded,
                  title: 'dailyRecords',
                ),
                _FutureFeatureTile(
                  icon: Icons.favorite_rounded,
                  title: 'anniversaries',
                ),
                _FutureFeatureTile(
                  icon: Icons.person_rounded,
                  title: 'userProfile',
                ),
                _FutureFeatureTile(
                  icon: Icons.settings_rounded,
                  title: 'appSettings',
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isCopying ? null : _copyBackupJson,
              icon: Icon(
                _isCopying ? Icons.hourglass_empty_rounded : Icons.copy_rounded,
              ),
              label: Text(_isCopying ? '正在复制' : '复制备份 JSON'),
            ),
          ),
        ],
      ),
    );
  }
}

const String feedbackEmail = 'your_email@example.com';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();

  @override
  void dispose() {
    _contentController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final content = _contentController.text.trim();
    final contact = _contactController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('写下你想说的话吧')));
      return;
    }

    final feedbackText = [
      '收件人：$feedbackEmail',
      '主题：暖桃日记反馈',
      '',
      content,
      if (contact.isNotEmpty) '',
      if (contact.isNotEmpty) '联系方式：$contact',
    ].join('\n');
    await Clipboard.setData(ClipboardData(text: feedbackText));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('反馈内容已复制，请发送到 $feedbackEmail')));
  }

  @override
  Widget build(BuildContext context) {
    return ProfileSettingScaffold(
      title: '意见反馈',
      subtitle: '你的感受会让暖桃日记慢慢变好',
      child: Column(
        children: [
          WarmCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '你可以将建议发送到：$feedbackEmail',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _contentController,
                  minLines: 5,
                  maxLines: 8,
                  decoration: softInputDecoration('写下你想说的话吧'),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _contactController,
                  decoration: softInputDecoration('联系方式，可选'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.copy_rounded),
              label: const Text('复制反馈内容'),
            ),
          ),
        ],
      ),
    );
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ProfileSettingScaffold(
      title: '关于暖桃日记',
      subtitle: '一份温柔的生活手账',
      child: WarmCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.peach, AppColors.lavender],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_florist_rounded,
                  color: Colors.white,
                  size: 38,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                '暖桃日记',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '版本 1.0.0',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              '暖桃日记是一份温柔的生活手账。它帮你记录过去、书写今天、安排未来，把每一个值得记住的日子轻轻收藏起来。',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                height: 1.7,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileSettingScaffold extends StatelessWidget {
  const ProfileSettingScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
    super.key,
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

class _ThemeOptionCard extends StatelessWidget {
  const _ThemeOptionCard({
    required this.theme,
    required this.selected,
    required this.onTap,
  });

  final ProfileThemeOption theme;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: WarmCard(
        padding: const EdgeInsets.all(18),
        color: theme.soft.withValues(alpha: 0.86),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [theme.secondary, theme.primary],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    theme.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    theme.description,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded, color: AppColors.roseDeep),
          ],
        ),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  const _SaveButton({
    required this.isSaving,
    required this.label,
    required this.onPressed,
  });

  final bool isSaving;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isSaving ? null : onPressed,
        icon: Icon(
          isSaving ? Icons.hourglass_empty_rounded : Icons.save_rounded,
        ),
        label: Text(isSaving ? '正在保存' : label),
      ),
    );
  }
}

class _FutureFeatureTile extends StatelessWidget {
  const _FutureFeatureTile({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: AppColors.roseDeep, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration softInputDecoration(String hintText) {
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

void _showSaveFailed(BuildContext context) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(const SnackBar(content: Text('保存失败，请稍后再试')));
}
