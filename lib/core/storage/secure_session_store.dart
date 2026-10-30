import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Guarda os SEGREDOS da sessão — JWT, refresh token e expiração — em
/// armazenamento seguro (Keychain no iOS, EncryptedSharedPreferences no Android).
///
/// Substitui o uso de `shared_preferences` para o token/refresh (antes em texto
/// puro). Os dados NÃO sensíveis do usuário (nome, e-mail, etc.) seguem em
/// `shared_preferences`, consumidos pelas telas. Nada aqui deve ir para log.
class SecureSessionStore {
  SecureSessionStore._();
  static final SecureSessionStore instance = SecureSessionStore._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const _kToken = 'jwt_token';
  static const _kRefresh = 'refresh_token';
  static const _kExpiry = 'token_expiry_ms';

  Future<String?> getToken() => _storage.read(key: _kToken);
  Future<void> setToken(String token) => _storage.write(key: _kToken, value: token);

  Future<String?> getRefreshToken() => _storage.read(key: _kRefresh);
  Future<void> setRefreshToken(String value) => _storage.write(key: _kRefresh, value: value);

  Future<int?> getTokenExpiryMs() async {
    final raw = await _storage.read(key: _kExpiry);
    return raw == null ? null : int.tryParse(raw);
  }

  Future<void> setTokenExpiryMs(int epochMs) =>
      _storage.write(key: _kExpiry, value: epochMs.toString());

  Future<bool> hasToken() async {
    final t = await getToken();
    return t != null && t.isNotEmpty;
  }

  /// Limpa os segredos da sessão (logout).
  Future<void> clear() => _storage.deleteAll();
}
