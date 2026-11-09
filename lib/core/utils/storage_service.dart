import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  StorageService(this._prefs);

  static const String _keyBaseUrl = 'server_base_url';
  static const String _keyToken = 'auth_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUser = 'user_profile';
  static const String _keySelectedOutletId = 'selected_outlet_id';
  static const String _keyPendingCheckout = 'pending_checkout';
  static const String _keyInstallationId = 'pos_installation_id';
  static const String _keyDeviceId = 'pos_device_id';
  static const String _keyDeviceToken = 'pos_device_token';

  // Default base URL is https://10.0.2.2:7100 for Android emulator (HTTPS backend)
  // If iOS/Web, users can use localhost or change it in settings
  String get baseUrl =>
      _prefs.getString(_keyBaseUrl) ?? 'https://10.0.2.2:7100';

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
    await _prefs.remove(_keyPendingCheckout);
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

  Future<bool> clearSelectedOutletId() async {
    return await _prefs.remove(_keySelectedOutletId);
  }

  Future<bool> savePendingCheckout(Map<String, dynamic> payload) async {
    return _prefs.setString(_keyPendingCheckout, jsonEncode(payload));
  }

  Map<String, dynamic>? getPendingCheckout() {
    final value = _prefs.getString(_keyPendingCheckout);
    if (value == null) return null;
    try {
      return jsonDecode(value) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<bool> clearPendingCheckout() => _prefs.remove(_keyPendingCheckout);

  Future<String?> get posDeviceId => _readSecure(_keyDeviceId);
  Future<String?> get posDeviceToken => _readSecure(_keyDeviceToken);

  Future<String?> _readSecure(String key) async {
    try {
      return await _secureStorage.read(key: key);
    } on MissingPluginException {
      // Widget/unit tests do not register native secure-storage channels.
      return null;
    }
  }

  Future<void> savePosDeviceBinding(String deviceId, String token) async {
    await _secureStorage.write(key: _keyDeviceId, value: deviceId);
    await _secureStorage.write(key: _keyDeviceToken, value: token);
  }

  Future<void> clearPosDeviceBinding() async {
    await _secureStorage.delete(key: _keyDeviceId);
    await _secureStorage.delete(key: _keyDeviceToken);
  }

  Future<String> getOrCreateInstallationId() async {
    final existing = _prefs.getString(_keyInstallationId);
    if (existing != null) return existing;

    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((value) => value.toRadixString(16).padLeft(2, '0')).join();
    final created = '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
    await _prefs.setString(_keyInstallationId, created);
    return created;
  }
}
