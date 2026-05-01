import 'dart:io';

import 'package:flutter/material.dart';
import 'package:pink_diary_calendar/models/app_settings.dart';
import 'package:pink_diary_calendar/models/user_profile.dart';
import 'package:pink_diary_calendar/pages/edit_profile_page.dart';
import 'package:pink_diary_calendar/pages/profile_settings_pages.dart';
import 'package:pink_diary_calendar/services/local_storage_service.dart';
import 'package:pink_diary_calendar/theme/app_colors.dart';
import 'package:pink_diary_calendar/utils/profile_theme_utils.dart';
import 'package:pink_diary_calendar/widgets/warm_card.dart';
import 'package:pink_diary_calendar/widgets/warm_page_scaffold.dart';
import 'package:pink_diary_calendar/widgets/warm_page_title.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final LocalStorageService _storageService = const LocalStorageService();

  UserProfile _profile = UserProfile.defaults();
  AppSettings _settings = AppSettings.defaults();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    final profile = await _storageService.loadUserProfile();
    final settings = await _storageService.loadAppSettings();
    if (!mounted) {
      return;
    }
    setState(() {
      _profile = profile;
      _settings = settings;
      _isLoading = false;
    });
  }

  Future<void> _openPage(Widget page) async {
    final result = await Navigator.of(
      context,
    ).push<bool>(MaterialPageRoute(builder: (_) => page));
    if (!mounted) {
      return;
    }
    await _loadProfileData();
    if (result == true && mounted) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('已经为你保存好啦')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ProfileThemeUtils.byKey(_profile.themeKey);

    return WarmPageScaffold(
      child: ListView(
        key: const PageStorageKey('profile-page'),
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
        children: [
          const WarmPageTitle(
            title: '我的',
            subtitle: '给自己的生活手账留一页封面',
            icon: Icons.person_rounded,
          ),
          const SizedBox(height: 20),
          _CoverCard(profile: _profile, theme: theme, isLoading: _isLoading),
          const SizedBox(height: 18),
          _SettingGroup(
            title: '我的资料',
            children: [
              _SettingEntry(
                icon: Icons.badge_outlined,
                title: '编辑资料',
                description: '头像、昵称和签名',
                onTap: () => _openPage(
                  EditProfilePage(
                    profile: _profile,
                    storageService: _storageService,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SettingGroup(
            title: '个性装扮',
            children: [
              _SettingEntry(
                icon: Icons.palette_outlined,
                title: '主题装扮',
                description: '当前：${theme.name}',
                onTap: () => _openPage(
                  ThemeSettingsPage(
                    currentThemeKey: _profile.themeKey,
                    storageService: _storageService,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _SettingGroup(
            title: '通知设置',
            children: [
              _SettingEntry(
                icon: Icons.notifications_none_rounded,
                title: '纪念日提醒',
                description: _notificationDescription(),
                onTap: () => _openPage(
                  ReminderSettingsPage(
                    settings: _settings,
                    storageService: _storageService,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _notificationDescription() {
    if (!_settings.anniversaryNotificationEnabled) {
      return '未开启';
    }
    if (!_settings.notificationPermissionGranted) {
      return '系统通知权限未开启';
    }
    return '每日 ${_settings.anniversaryReminderTime} 提醒重要日子';
  }
}

class _CoverCard extends StatelessWidget {
  const _CoverCard({
    required this.profile,
    required this.theme,
    required this.isLoading,
  });

  final UserProfile profile;
  final ProfileThemeOption theme;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return WarmCard(
      padding: EdgeInsets.zero,
      color: theme.soft.withValues(alpha: 0.86),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.soft.withValues(alpha: 0.96),
              AppColors.milk.withValues(alpha: 0.92),
            ],
          ),
        ),
        child: Row(
          children: [
            _ProfileAvatar(profile: profile, theme: theme),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isLoading ? '小桃子' : profile.nickname,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    profile.signature.isEmpty ? '今天也要好好生活' : profile.signature,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.auto_awesome_rounded,
              color: theme.primary.withValues(alpha: 0.8),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.profile, required this.theme});

  final UserProfile profile;
  final ProfileThemeOption theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 82,
      height: 82,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [theme.secondary, theme.primary.withValues(alpha: 0.74)],
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.9),
          width: 3,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: profile.avatarPath.isEmpty
          ? const Icon(
              Icons.local_florist_rounded,
              color: Colors.white,
              size: 35,
            )
          : Image.file(
              File(profile.avatarPath),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.local_florist_rounded,
                  color: Colors.white,
                  size: 35,
                );
              },
            ),
    );
  }
}

class _SettingGroup extends StatelessWidget {
  const _SettingGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppColors.roseDeep,
              fontSize: 15,
            ),
          ),
        ),
        WarmCard(
          padding: EdgeInsets.zero,
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingEntry extends StatelessWidget {
  const _SettingEntry({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.blush.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: AppColors.roseDeep, size: 21),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.muted,
                      fontSize: 15,
                      height: 1.35,
                    ),
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
