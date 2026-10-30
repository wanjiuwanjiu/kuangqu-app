import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 令牌安全存储：access_token / refresh_token 存系统安全区
class TokenStore {
  TokenStore._();
  static final TokenStore instance = TokenStore._();

  static const _storage = FlutterSecureStorage();

  static const _kAccess = 'access_token';
  static const _kRefresh = 'refresh_token';

  String? _cachedAccess;
  String? _cachedRefresh;

  String? get accessToken => _cachedAccess;
  String? get refreshToken => _cachedRefresh;

  Future<void> load() async {
    _cachedAccess = await _storage.read(key: _kAccess);
    _cachedRefresh = await _storage.read(key: _kRefresh);
  }

  Future<void> save({required String access, required String refresh}) async {
    _cachedAccess = access;
    _cachedRefresh = refresh;
    await _storage.write(key: _kAccess, value: access);
    await _storage.write(key: _kRefresh, value: refresh);
  }

  Future<void> clear() async {
    _cachedAccess = null;
    _cachedRefresh = null;
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
  }
}
