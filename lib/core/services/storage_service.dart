import 'package:shared_preferences/shared_preferences.dart';

/// Service penyimpanan data ringan via SharedPreferences.
class StorageService {
  StorageService._();

  static final StorageService _instance = StorageService._();

  static StorageService get instance => _instance;

  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // --- String ---
  String? getString(String key) => _prefs.getString(key);
  Future<bool> setString(String key, String value) =>
      _prefs.setString(key, value);
  Future<bool> remove(String key) => _prefs.remove(key);

  // --- List<String> ---
  List<String>? getStringList(String key) => _prefs.getStringList(key);
  Future<bool> setStringList(String key, List<String> value) =>
      _prefs.setStringList(key, value);

  // --- Bool ---
  bool? getBool(String key) => _prefs.getBool(key);
  Future<bool> setBool(String key, bool value) => _prefs.setBool(key, value);

  Future<bool> clear() => _prefs.clear();
}
