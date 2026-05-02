import 'dart:convert';

import 'package:pink_diary_calendar/models/app_settings.dart';
import 'package:pink_diary_calendar/models/anniversary.dart';
import 'package:pink_diary_calendar/models/daily_record.dart';
import 'package:pink_diary_calendar/models/life_list.dart';
import 'package:pink_diary_calendar/models/user_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  const LocalStorageService();

  static const String _dailyRecordsKey = 'dailyRecords';
  static const String _anniversariesKey = 'anniversaries';
  static const String _userProfileKey = 'userProfile';
  static const String _appSettingsKey = 'appSettings';
  static const String _lifeListsKey = 'lifeLists';
  static const String _hasAgreedLegalKey = 'hasAgreedLegal';
  static const String _agreedTermsVersionKey = 'agreedTermsVersion';
  static const String _agreedPrivacyVersionKey = 'agreedPrivacyVersion';
  static const String _agreedAtKey = 'agreedAt';

  Future<bool> hasValidLegalAgreement({
    required String termsVersion,
    required String privacyVersion,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    final hasAgreed = preferences.getBool(_hasAgreedLegalKey) ?? false;
    final agreedTermsVersion = preferences.getString(_agreedTermsVersionKey);
    final agreedPrivacyVersion = preferences.getString(
      _agreedPrivacyVersionKey,
    );

    return hasAgreed &&
        agreedTermsVersion == termsVersion &&
        agreedPrivacyVersion == privacyVersion;
  }

  Future<void> saveLegalAgreement({
    required String termsVersion,
    required String privacyVersion,
  }) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_hasAgreedLegalKey, true);
    await preferences.setString(_agreedTermsVersionKey, termsVersion);
    await preferences.setString(_agreedPrivacyVersionKey, privacyVersion);
    await preferences.setString(_agreedAtKey, DateTime.now().toIso8601String());
  }

  Future<Map<String, DailyRecord>> loadDailyRecords() async {
    final preferences = await SharedPreferences.getInstance();
    final rawRecords = preferences.getString(_dailyRecordsKey);
    if (rawRecords == null || rawRecords.isEmpty) {
      return {};
    }

    try {
      final decoded = jsonDecode(rawRecords);
      if (decoded is! Map<String, dynamic>) {
        return {};
      }

      return decoded.map((dateKey, value) {
        if (value is Map<String, dynamic>) {
          return MapEntry(dateKey, DailyRecord.fromJson(value));
        }

        if (value is Map) {
          return MapEntry(
            dateKey,
            DailyRecord.fromJson(Map<String, dynamic>.from(value)),
          );
        }

        return MapEntry(
          dateKey,
          DailyRecord(
            date: dateKey,
            text: '',
            updatedAt: DateTime.fromMillisecondsSinceEpoch(0),
          ),
        );
      });
    } catch (_) {
      return {};
    }
  }

  Future<DailyRecord?> loadDailyRecord(String dateKey) async {
    final records = await loadDailyRecords();
    return records[dateKey];
  }

  Future<Set<String>> loadRecordedDateKeys() async {
    final records = await loadDailyRecords();
    return records.entries
        .where((entry) => entry.value.hasContent)
        .map((entry) => entry.key)
        .toSet();
  }

  Future<void> saveDailyRecord(DailyRecord record) async {
    final preferences = await SharedPreferences.getInstance();
    final records = await loadDailyRecords();
    records[record.date] = record;

    final payload = records.map(
      (dateKey, dailyRecord) => MapEntry(dateKey, dailyRecord.toJson()),
    );
    await preferences.setString(_dailyRecordsKey, jsonEncode(payload));
  }

  Future<List<Anniversary>> loadAnniversaries() async {
    final preferences = await SharedPreferences.getInstance();
    final rawAnniversaries = preferences.getString(_anniversariesKey);
    if (rawAnniversaries == null || rawAnniversaries.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(rawAnniversaries);
      if (decoded is! List) {
        return [];
      }

      return decoded
          .whereType<Map>()
          .map(
            (entry) => Anniversary.fromJson(Map<String, dynamic>.from(entry)),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveAnniversaries(List<Anniversary> anniversaries) async {
    final preferences = await SharedPreferences.getInstance();
    final payload = anniversaries.map((entry) => entry.toJson()).toList();
    await preferences.setString(_anniversariesKey, jsonEncode(payload));
  }

  Future<void> addAnniversary(Anniversary anniversary) async {
    final anniversaries = await loadAnniversaries();
    await saveAnniversaries([...anniversaries, anniversary]);
  }

  Future<void> updateAnniversary(Anniversary anniversary) async {
    final anniversaries = await loadAnniversaries();
    final nextAnniversaries = anniversaries.map((entry) {
      return entry.id == anniversary.id ? anniversary : entry;
    }).toList();
    await saveAnniversaries(nextAnniversaries);
  }

  Future<void> deleteAnniversary(String id) async {
    final anniversaries = await loadAnniversaries();
    final nextAnniversaries = anniversaries
        .where((entry) => entry.id != id)
        .toList();
    await saveAnniversaries(nextAnniversaries);
  }

  Future<UserProfile> loadUserProfile() async {
    final preferences = await SharedPreferences.getInstance();
    final rawProfile = preferences.getString(_userProfileKey);
    if (rawProfile == null || rawProfile.isEmpty) {
      return UserProfile.defaults();
    }

    try {
      final decoded = jsonDecode(rawProfile);
      if (decoded is Map<String, dynamic>) {
        return UserProfile.fromJson(decoded);
      }
      if (decoded is Map) {
        return UserProfile.fromJson(Map<String, dynamic>.from(decoded));
      }
      return UserProfile.defaults();
    } catch (_) {
      return UserProfile.defaults();
    }
  }

  Future<void> saveUserProfile(UserProfile profile) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_userProfileKey, jsonEncode(profile.toJson()));
  }

  Future<AppSettings> loadAppSettings() async {
    final preferences = await SharedPreferences.getInstance();
    final rawSettings = preferences.getString(_appSettingsKey);
    if (rawSettings == null || rawSettings.isEmpty) {
      return AppSettings.defaults();
    }

    try {
      final decoded = jsonDecode(rawSettings);
      if (decoded is Map<String, dynamic>) {
        return AppSettings.fromJson(decoded);
      }
      if (decoded is Map) {
        return AppSettings.fromJson(Map<String, dynamic>.from(decoded));
      }
      return AppSettings.defaults();
    } catch (_) {
      return AppSettings.defaults();
    }
  }

  Future<void> saveAppSettings(AppSettings settings) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_appSettingsKey, jsonEncode(settings.toJson()));
  }

  Future<void> saveThemeKey(String themeKey) async {
    final profile = await loadUserProfile();
    final settings = await loadAppSettings();
    final now = DateTime.now();

    await saveUserProfile(profile.copyWith(themeKey: themeKey, updatedAt: now));
    await saveAppSettings(
      settings.copyWith(themeKey: themeKey, updatedAt: now),
    );
  }

  Future<List<LifeList>> getLifeLists() {
    return loadLifeLists();
  }

  Future<List<LifeList>> loadLifeLists() async {
    final preferences = await SharedPreferences.getInstance();
    final rawLifeLists = preferences.getString(_lifeListsKey);
    if (rawLifeLists == null || rawLifeLists.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(rawLifeLists);
      if (decoded is! List) {
        return [];
      }

      return decoded
          .whereType<Map>()
          .map((entry) => LifeList.fromJson(Map<String, dynamic>.from(entry)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<LifeList>> loadLifeListsByType(String type) async {
    final lifeLists = await loadLifeLists();
    return lifeLists.where((entry) => entry.type == type).toList()
      ..sort((first, second) => second.updatedAt.compareTo(first.updatedAt));
  }

  Future<void> saveLifeLists(List<LifeList> lifeLists) async {
    final preferences = await SharedPreferences.getInstance();
    final payload = lifeLists.map((entry) => entry.toJson()).toList();
    await preferences.setString(_lifeListsKey, jsonEncode(payload));
  }

  Future<void> addLifeList(LifeList lifeList) async {
    final lifeLists = await loadLifeLists();
    await saveLifeLists([...lifeLists, lifeList]);
  }

  Future<void> updateLifeList(LifeList lifeList) async {
    final lifeLists = await loadLifeLists();
    final nextLifeLists = lifeLists.map((entry) {
      return entry.id == lifeList.id ? lifeList : entry;
    }).toList();
    await saveLifeLists(nextLifeLists);
  }

  Future<void> deleteLifeList(String id) async {
    final lifeLists = await loadLifeLists();
    final nextLifeLists = lifeLists.where((entry) => entry.id != id).toList();
    await saveLifeLists(nextLifeLists);
  }

  Future<String> exportBackupJson() async {
    final dailyRecords = await loadDailyRecords();
    final anniversaries = await loadAnniversaries();
    final lifeLists = await loadLifeLists();
    final userProfile = await loadUserProfile();
    final appSettings = await loadAppSettings();

    final payload = {
      'appName': '暖桃日记',
      'exportedAt': DateTime.now().toIso8601String(),
      'dailyRecords': dailyRecords.map(
        (dateKey, record) => MapEntry(dateKey, record.toJson()),
      ),
      'anniversaries': anniversaries.map((entry) => entry.toJson()).toList(),
      'lifeLists': lifeLists.map((entry) => entry.toJson()).toList(),
      'userProfile': userProfile.toJson(),
      'appSettings': appSettings.toJson(),
    };

    return const JsonEncoder.withIndent('  ').convert(payload);
  }
}
