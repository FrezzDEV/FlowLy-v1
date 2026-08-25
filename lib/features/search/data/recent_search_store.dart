import 'package:shared_preferences/shared_preferences.dart';

final class RecentSearchStore {
  static const _key = 'flowly.recent_searches';
  static const _maxItems = 8;

  const RecentSearchStore();

  Future<List<String>> load() async {
    final preferences = SharedPreferencesAsync();
    return List<String>.from(
      await preferences.getStringList(_key) ?? const <String>[],
    );
  }

  Future<void> add(String query) async {
    final value = query.trim();
    if (value.isEmpty) return;

    final preferences = SharedPreferencesAsync();
    final current = List<String>.from(
      await preferences.getStringList(_key) ?? const <String>[],
    );

    current
      ..remove(value)
      ..insert(0, value);

    if (current.length > _maxItems) {
      current.removeRange(_maxItems, current.length);
    }

    await preferences.setStringList(_key, current);
  }

  Future<void> remove(String query) async {
    final preferences = SharedPreferencesAsync();
    final current = List<String>.from(
      await preferences.getStringList(_key) ?? const <String>[],
    )..remove(query);

    await preferences.setStringList(_key, current);
  }

  Future<void> clear() async {
    await SharedPreferencesAsync().remove(_key);
  }
}
