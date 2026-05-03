import 'package:flutter/foundation.dart';
import 'package:pink_diary_calendar/services/local_storage_service.dart';
import 'package:pink_diary_calendar/utils/profile_theme_utils.dart';

class AppThemeController extends ChangeNotifier {
  AppThemeController._();

  static final AppThemeController instance = AppThemeController._();

  final LocalStorageService _storageService = const LocalStorageService();

  String _themeKey = 'minimalWhite';
  bool _hasLoaded = false;

  String get themeKey => _themeKey;

  Future<void> loadTheme() async {
    if (_hasLoaded) {
      return;
    }

    try {
      final settings = await _storageService.loadAppSettings();
      _themeKey = ProfileThemeUtils.byKey(settings.themeKey).key;
    } catch (_) {
      _themeKey = 'minimalWhite';
    }
    _hasLoaded = true;
    notifyListeners();
  }

  Future<void> setThemeKey(String themeKey) async {
    final normalizedThemeKey = ProfileThemeUtils.byKey(themeKey).key;
    if (_themeKey != normalizedThemeKey) {
      _themeKey = normalizedThemeKey;
      notifyListeners();
    }
    await _storageService.saveThemeKey(normalizedThemeKey);
  }
}
