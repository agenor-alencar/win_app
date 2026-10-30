import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Armazenamento SEGURO (Keychain no iOS, EncryptedSharedPreferences no Android)
/// de TUDO que é sensível: sessão (JWT, refresh, expiração) e o perfil do
/// usuário (id, nome, e-mail, CPF, telefone) — CPF é PII e nunca deve ficar em
/// texto puro no `shared_preferences`. Nada aqui deve ir para log.
class SecureSessionStore {
  SecureSessionStore._();
  static final SecureSessionStore instance = SecureSessionStore._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // Sessão
  static const _kToken = 'jwt_token';
  static const _kRefresh = 'refresh_token';
  static const _kExpiry = 'token_expiry_ms';
  // Perfil (PII)
  static const _kUserId = 'user_id';
  static const _kUserNome = 'user_nome';
  static const _kUserEmail = 'user_email';
  static const _kUserCpf = 'user_cpf';
  static const _kUserTelefone = 'user_telefone';

  // ── Sessão ──────────────────────────────────────────────────────────────────
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

  // ── Perfil (PII) ──────────────────────────────────────────────────────────
  Future<String?> getUserId() => _storage.read(key: _kUserId);
  Future<String?> getUserNome() => _storage.read(key: _kUserNome);
  Future<String?> getUserEmail() => _storage.read(key: _kUserEmail);
  Future<String?> getUserCpf() => _storage.read(key: _kUserCpf);
  Future<String?> getUserTelefone() => _storage.read(key: _kUserTelefone);

  /// Persiste o perfil devolvido no login/registro/OTP.
  Future<void> saveUser(Map<String, dynamic> user) async {
    await _storage.write(key: _kUserId, value: (user['id'] ?? '').toString());
    await _storage.write(key: _kUserNome, value: (user['nome'] ?? '').toString());
    await _storage.write(key: _kUserEmail, value: (user['email'] ?? '').toString());
    await _storage.write(key: _kUserCpf, value: (user['cpf'] ?? '').toString());
    await _storage.write(key: _kUserTelefone, value: (user['telefone'] ?? '').toString());
  }

  /// Limpa TUDO (sessão + perfil) — usado no logout e na expiração definitiva.
  Future<void> clear() => _storage.deleteAll();
}
