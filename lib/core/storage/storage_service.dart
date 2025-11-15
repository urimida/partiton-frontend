import 'package:shared_preferences/shared_preferences.dart';
import 'package:partition_app/core/config/app_config.dart';

class StorageService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static Future<bool> setToken(String token) async {
    return await _prefs?.setString(AppConfig.tokenKey, token) ?? false;
  }

  static Future<String?> getToken() async {
    return _prefs?.getString(AppConfig.tokenKey);
  }

  static Future<bool> removeToken() async {
    return await _prefs?.remove(AppConfig.tokenKey) ?? false;
  }

  static Future<bool> setUserId(String userId) async {
    return await _prefs?.setString(AppConfig.userIdKey, userId) ?? false;
  }

  static Future<String?> getUserId() async {
    return _prefs?.getString(AppConfig.userIdKey);
  }

  static Future<bool> clear() async {
    return await _prefs?.clear() ?? false;
  }
}

