import 'package:flutter/foundation.dart';
import 'package:pink_diary_calendar/services/local_storage_service.dart';

class AppThemeController extends ChangeNotifier {
  AppThemeController._();

  static final AppThemeController instance = AppThemeController._();

  final LocalStorageService _storageService = const LocalStorageService();

  String _themeKey = 'pink';
  bool _hasLoaded = false;

  String get themeKey => _themeKey;

  Future<void> loadTheme() async {
    if (_hasLoaded) {
      return;
    }

    try {
      final settings = await _storageService.loadAppSettings();
      _themeKey = settings.themeKey;
    } catch (_) {
      _themeKey = 'pink';
    }
    _hasLoaded = true;
    notifyListeners();
  }

  Future<void> setThemeKey(String themeKey) async {
    if (_themeKey != themeKey) {
      _themeKey = themeKey;
      notifyListeners();
    }
    await _storageService.saveThemeKey(themeKey);
  }
}
