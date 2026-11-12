import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/table_config.dart';

/// Single global instance, loaded in main().
final AppStore store = AppStore();

/// Storage: List (screens) of List (tables) of {name, id, filter, n}.
class AppStore extends ChangeNotifier {
  static const _key = 'screens';
  static const _currentScreenKey = 'current_screen';

  final List<List<TableConfig>> _screens = [];
  SharedPreferences? _prefs;
  int _currentScreen = 0;

  int get currentScreen => _currentScreen;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    _currentScreen = _prefs!.getInt(_currentScreenKey) ?? 0;
    final raw = _prefs!.getString(_key);
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw) as List;
      _screens
        ..clear()
        ..addAll(
          decoded.map(
            (s) => (s as List)
                .map((t) => TableConfig.fromJson(t as Map<String, dynamic>))
                .toList(),
          ),
        );
    } catch (_) {
      _screens.clear();
    }
  }

  void setCurrentScreen(int screen) {
    if (screen < 0 || screen == _currentScreen) return;
    _currentScreen = screen;
    _prefs?.setInt(_currentScreenKey, screen);
  }

  List<TableConfig> tablesOf(int screen) =>
      screen < _screens.length ? _screens[screen] : const <TableConfig>[];

  void addTable(int screen, TableConfig table) {
    while (_screens.length <= screen) {
      _screens.add([]);
    }
    _screens[screen].add(table);
    changed();
  }

  void removeTable(int screen, TableConfig table) {
    if (screen < _screens.length) {
      _screens[screen].remove(table);
      changed();
    }
  }

  void reorder(int screen, int oldIndex, int newIndex) {
    if (screen >= _screens.length) return;
    final list = _screens[screen];
    list.insert(newIndex, list.removeAt(oldIndex));
    changed();
  }

  /// Call after mutating a TableConfig in place (n, filter...).
  void changed() {
    notifyListeners();
    _prefs?.setString(
      _key,
      jsonEncode(
        _screens.map((s) => s.map((t) => t.toJson()).toList()).toList(),
      ),
    );
  }
}
