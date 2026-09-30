import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Non-sensitive local persistence: preferences, recent searches and
/// offline caches of public catalog data. Never put tokens or personal
/// secrets here — use [TokenStorage] for those.
class LocalCache {
  LocalCache(this._prefs);

  final SharedPreferences _prefs;

  static const _onboardingSeen = 'app.onboarding_seen';
  static const _recentSearches = 'search.recent';
  static const _recentlyViewed = 'catalog.recently_viewed';
  static const _categories = 'catalog.categories';
  static const _homeFeed = 'catalog.home_feed';
  static const _selectedAddressId = 'address.selected_id';
  static const _settings = 'app.settings';

  bool get onboardingSeen => _prefs.getBool(_onboardingSeen) ?? false;
  Future<void> setOnboardingSeen() => _prefs.setBool(_onboardingSeen, true);

  List<String> get recentSearches =>
      _prefs.getStringList(_recentSearches) ?? const [];
  Future<void> setRecentSearches(List<String> terms) =>
      _prefs.setStringList(_recentSearches, terms);

  String? get selectedAddressId => _prefs.getString(_selectedAddressId);
  Future<void> setSelectedAddressId(String? id) => id == null
      ? _prefs.remove(_selectedAddressId)
      : _prefs.setString(_selectedAddressId, id);

  List<Map<String, dynamic>> get recentlyViewed => _readList(_recentlyViewed);
  Future<void> setRecentlyViewed(List<Map<String, dynamic>> items) =>
      _writeJson(_recentlyViewed, items);

  List<Map<String, dynamic>> get cachedCategories => _readList(_categories);
  Future<void> cacheCategories(List<Map<String, dynamic>> items) =>
      _writeJson(_categories, items);

  Map<String, dynamic>? get cachedHomeFeed => _readMap(_homeFeed);
  Future<void> cacheHomeFeed(Map<String, dynamic> feed) =>
      _writeJson(_homeFeed, feed);

  Map<String, dynamic> get settings => _readMap(_settings) ?? const {};
  Future<void> saveSettings(Map<String, dynamic> value) =>
      _writeJson(_settings, value);

  /// Raw JSON access for the demo backend's persisted state.
  Object? readJson(String key) {
    final raw = _prefs.getString(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } on FormatException {
      return null;
    }
  }

  Future<void> writeJson(String key, Object value) => _writeJson(key, value);

  /// Clears cached catalog data while keeping preferences.
  Future<void> clearCatalogCache() async {
    await _prefs.remove(_categories);
    await _prefs.remove(_homeFeed);
    await _prefs.remove(_recentlyViewed);
  }

  /// Clears data belonging to the signed-in user.
  Future<void> clearUserData() async {
    await _prefs.remove(_selectedAddressId);
    await _prefs.remove(_recentSearches);
    await _prefs.remove(_recentlyViewed);
  }

  Future<void> _writeJson(String key, Object value) =>
      _prefs.setString(key, jsonEncode(value));

  List<Map<String, dynamic>> _readList(String key) {
    final decoded = readJson(key);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  Map<String, dynamic>? _readMap(String key) {
    final decoded = readJson(key);
    return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
  }
}
