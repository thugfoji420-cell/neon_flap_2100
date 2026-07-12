import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper around SharedPreferences providing typed, async access to all
/// persisted values. Centralising access keeps the storage keys consistent and
/// makes testing/mocking straightforward.
class StorageService {
  StorageService(this._prefs);

  final SharedPreferences _prefs;

  Future<bool> setInt(String key, int value) => _prefs.setInt(key, value);
  int? getInt(String key) => _prefs.getInt(key);

  Future<bool> setDouble(String key, double value) =>
      _prefs.setDouble(key, value);
  double? getDouble(String key) => _prefs.getDouble(key);

  Future<bool> setString(String key, String value) =>
      _prefs.setString(key, value);
  String? getString(String key) => _prefs.getString(key);

  Future<bool> setStringList(String key, List<String> value) =>
      _prefs.setStringList(key, value);
  List<String>? getStringList(String key) => _prefs.getStringList(key);

  Future<bool> remove(String key) => _prefs.remove(key);
}
