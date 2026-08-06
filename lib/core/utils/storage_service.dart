import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  static const String _keyBaseUrl = 'server_base_url';
  static const String _keyToken = 'auth_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUser = 'user_profile';
  static const String _keySelectedOutletId = 'selected_outlet_id';

  // Default base URL is https://10.0.2.2:7100 for Android emulator (HTTPS backend)
  // If iOS/Web, users can use localhost or change it in settings
  String get baseUrl => _prefs.getString(_keyBaseUrl) ?? 'https://10.0.2.2:7100';

  Future<bool> setBaseUrl(String url) async {
    return await _prefs.setString(_keyBaseUrl, url);
  }

  String? get token => _prefs.getString(_keyToken);

  Future<bool> setToken(String token) async {
    return await _prefs.setString(_keyToken, token);
  }

  String? get refreshToken => _prefs.getString(_keyRefreshToken);

  Future<bool> setRefreshToken(String token) async {
    return await _prefs.setString(_keyRefreshToken, token);
  }

  Future<bool> clearAuth() async {
    await _prefs.remove(_keyToken);
    await _prefs.remove(_keyRefreshToken);
    await _prefs.remove(_keyUser);
    await _prefs.remove(_keySelectedOutletId);
    return true;
  }

  Future<bool> saveUser(Map<String, dynamic> userJson) async {
    return await _prefs.setString(_keyUser, jsonEncode(userJson));
  }

  Map<String, dynamic>? getUser() {
    final userStr = _prefs.getString(_keyUser);
    if (userStr == null) return null;
    try {
      return jsonDecode(userStr) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  String? get selectedOutletId => _prefs.getString(_keySelectedOutletId);

  Future<bool> setSelectedOutletId(String outletId) async {
    return await _prefs.setString(_keySelectedOutletId, outletId);
  }
}
