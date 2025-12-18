import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:partition_app/core/config/app_config.dart';

class StorageService {
  static SharedPreferences? _prefs;
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Access Token을 flutter_secure_storage에 저장
  static Future<bool> setToken(String token) async {
    try {
      await _secureStorage.write(key: AppConfig.tokenKey, value: token);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Access Token을 flutter_secure_storage에서 읽기
  static Future<String?> getToken() async {
    try {
      return await _secureStorage.read(key: AppConfig.tokenKey);
    } catch (e) {
      return null;
    }
  }

  /// Access Token 삭제
  static Future<bool> removeToken() async {
    try {
      await _secureStorage.delete(key: AppConfig.tokenKey);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Refresh Token을 flutter_secure_storage에 저장
  static Future<bool> setRefreshToken(String refreshToken) async {
    try {
      await _secureStorage.write(key: AppConfig.refreshTokenKey, value: refreshToken);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Refresh Token을 flutter_secure_storage에서 읽기
  static Future<String?> getRefreshToken() async {
    try {
      return await _secureStorage.read(key: AppConfig.refreshTokenKey);
    } catch (e) {
      return null;
    }
  }

  /// Refresh Token 삭제
  static Future<bool> removeRefreshToken() async {
    try {
      await _secureStorage.delete(key: AppConfig.refreshTokenKey);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> setUserId(String userId) async {
    return await _prefs?.setString(AppConfig.userIdKey, userId) ?? false;
  }

  static Future<String?> getUserId() async {
    return _prefs?.getString(AppConfig.userIdKey);
  }

  static Future<bool> setUserName(String name) async {
    return await _prefs?.setString('user_name', name) ?? false;
  }

  static Future<String?> getUserName() async {
    return _prefs?.getString('user_name');
  }

  static Future<bool> setOnboardingCompleted(bool completed) async {
    return await _prefs?.setBool('onboarding_completed', completed) ?? false;
  }

  static Future<bool> isOnboardingCompleted() async {
    return _prefs?.getBool('onboarding_completed') ?? false;
  }

  static Future<bool> setHouseholdId(String householdId) async {
    return await _prefs?.setString('household_id', householdId) ?? false;
  }

  static Future<String?> getHouseholdId() async {
    return _prefs?.getString('household_id');
  }

  static Future<bool> clear() async {
    try {
      // Secure storage 삭제
      await _secureStorage.deleteAll();
      // SharedPreferences 삭제
      return await _prefs?.clear() ?? false;
    } catch (e) {
      return false;
    }
  }
}

