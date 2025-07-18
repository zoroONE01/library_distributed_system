import 'package:shared_preferences/shared_preferences.dart';

final localStorage = LocalStorageManager.instance;

class LocalStorageManager {
  LocalStorageManager._privateConstructor();
  static final LocalStorageManager instance =
      LocalStorageManager._privateConstructor();

  late SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<bool> write<T>(String key, T value) async {
    if (_prefs == null) await init();
    if (value is int) return _prefs!.setInt(key, value);
    if (value is double) return _prefs!.setDouble(key, value);
    if (value is bool) return _prefs!.setBool(key, value);
    if (value is String) return _prefs!.setString(key, value);
    if (value is List<String>) return _prefs!.setStringList(key, value);
    throw UnsupportedError('Type ${T.runtimeType} không được hỗ trợ');
  }

  T? read<T>(String key) {
    return _prefs?.get(key) as T?;
  }

  Future<bool> remove(String key) async {
    if (_prefs == null) await init();
    return _prefs!.remove(key);
  }

  Future<bool> clear() async {
    if (_prefs == null) await init();
    return _prefs!.clear();
  }
}
