import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/table_config.dart';
import 'transitous_api.dart';

/// Single global instance, loaded in main().
final AppStore store = AppStore();

/// User configuration, stored sparsely so high numbered screens stay cheap.
class AppStore extends ChangeNotifier {
  static const _key = 'screens';
  static const _currentScreenKey = 'current_screen';
  static const _themeKey = 'theme_mode';
  static const _apiKey = 'motis_instance';

  final Map<int, List<TableConfig>> _screens = {};
  SharedPreferences? _prefs;
  int _currentScreen = 0;
  ThemeMode _themeMode = ThemeMode.system;
  String _apiBaseUrl = TransitousApi.defaultBaseUrl;

  int get currentScreen => _currentScreen;
  ThemeMode get themeMode => _themeMode;
  String get apiBaseUrl => _apiBaseUrl;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    _currentScreen = _prefs!.getInt(_currentScreenKey) ?? 0;
    _themeMode = switch (_prefs!.getString(_themeKey)) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    _apiBaseUrl = _prefs!.getString(_apiKey) ?? TransitousApi.defaultBaseUrl;
    TransitousApi.setBaseUrl(_apiBaseUrl);

    final raw = _prefs!.getString(_key);
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw);
      _screens
        ..clear()
        ..addAll(_decodeScreens(decoded));
    } catch (_) {
      _screens.clear();
    }
  }

  Map<int, List<TableConfig>> _decodeScreens(dynamic decoded) {
    final result = <int, List<TableConfig>>{};
    // Current sparse format: {"1":[...],"9000":[...]}
    if (decoded is Map) {
      for (final entry in decoded.entries) {
        final screen = int.tryParse(entry.key.toString());
        if (screen == null || screen < 0 || entry.value is! List) continue;
        final tables = (entry.value as List)
            .map(
              (t) => TableConfig.fromJson(Map<String, dynamic>.from(t as Map)),
            )
            .toList();
        if (tables.isNotEmpty) result[screen] = tables;
      }
    } else {
      throw const FormatException('Invalid screens data');
    }
    return result;
  }

  void setCurrentScreen(int screen) {
    if (screen < 0 || screen == _currentScreen) return;
    _currentScreen = screen;
    _prefs?.setInt(_currentScreenKey, screen);
  }

  List<TableConfig> tablesOf(int screen) =>
      _screens[screen] ?? const <TableConfig>[];

  void addTable(int screen, TableConfig table) {
    (_screens[screen] ??= []).add(table);
    changed();
  }

  void removeTable(int screen, TableConfig table) {
    final tables = _screens[screen];
    if (tables?.remove(table) ?? false) {
      if (tables!.isEmpty) _screens.remove(screen);
      changed();
    }
  }

  void reorder(int screen, int oldIndex, int newIndex) {
    final list = _screens[screen];
    if (list == null) return;
    list.insert(newIndex, list.removeAt(oldIndex));
    changed();
  }

  void setThemeMode(ThemeMode value) {
    if (_themeMode == value) return;
    _themeMode = value;
    _prefs?.setString(_themeKey, switch (value) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      _ => 'system',
    });
    notifyListeners();
  }

  void setApiBaseUrl(String value) {
    final normalized = TransitousApi.normalizeBaseUrl(value);
    _apiBaseUrl = normalized;
    TransitousApi.setBaseUrl(normalized);
    _prefs?.setString(_apiKey, normalized);
    notifyListeners();
  }

  Map<String, dynamic> exportData() => {
    'settings': {
      'theme': switch (_themeMode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        _ => 'system',
      },
      'motisInstance': _apiBaseUrl,
    },
    'screens': _encodeScreens(),
  };

  Map<String, List<Map<String, dynamic>>> _encodeScreens() => {
    for (final entry in _screens.entries)
      if (entry.value.isNotEmpty)
        '${entry.key}': entry.value.map((table) => table.toJson()).toList(),
  };

  Future<void> restoreData(Map<String, dynamic> data) async {
    final parsed = _decodeScreens(data['screens']);
    final settings = data['settings'];
    var theme = ThemeMode.system;
    var apiUrl = TransitousApi.defaultBaseUrl;
    if (settings is Map) {
      theme = switch (settings['theme']) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
      final rawUrl = settings['motisInstance'];
      if (rawUrl is String && rawUrl.trim().isNotEmpty) {
        apiUrl = TransitousApi.normalizeBaseUrl(rawUrl);
      }
    }
    _screens
      ..clear()
      ..addAll(parsed);
    _themeMode = theme;
    _apiBaseUrl = apiUrl;
    TransitousApi.setBaseUrl(apiUrl);
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    await _prefs?.setString(_key, jsonEncode(_encodeScreens()));
    await _prefs?.setString(_themeKey, switch (_themeMode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      _ => 'system',
    });
    await _prefs?.setString(_apiKey, _apiBaseUrl);
    await _prefs?.setInt(_currentScreenKey, _currentScreen);
  }

  /// Call after mutating a TableConfig in place (n, filter...).
  void changed() {
    notifyListeners();
    _prefs?.setString(_key, jsonEncode(_encodeScreens()));
  }
}
