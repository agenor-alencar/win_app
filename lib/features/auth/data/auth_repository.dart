import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:win_app/core/network/api_client.dart';
import 'package:win_app/core/network/api_exception.dart';
import 'package:win_app/core/storage/secure_session_store.dart';

/// Autenticação do app.
///
/// **Primário — login por telefone (OTP):** `POST /auth/request-code {telefone}`
/// envia o código por SMS; `POST /auth/verify-code {telefone, codigo}` valida e
/// devolve `{access_token, usuario}`. Esse é o par canônico (o backend gera e
/// valida o OTP e já faz o login/criação por telefone). O par
/// `enviar-sms/validar-sms` (Twilio Verify) é uma alternativa e NÃO é usado aqui.
///
/// **Secundário — e-mail/senha:** `POST /auth/login` e `POST /auth/register`.
///
/// O refresh no 401 é tratado pelo interceptor do [ApiClient].
class AuthRepository {
  AuthRepository({Dio? dio, SecureSessionStore? session})
      : _dio = dio ?? ApiClient.instance.dio,
        _session = session ?? SecureSessionStore.instance;

  final Dio _dio;
  final SecureSessionStore _session;

  // ── OTP (primário) ─────────────────────────────────────────────────────────

  /// Solicita o envio do código OTP por SMS. Lança [ApiException] em falha
  /// (ex.: 429 rate limit, 503 SMS indisponível) com a mensagem do servidor.
  Future<void> requestCode(String telefone) async {
    try {
      await _dio.post('/auth/request-code', data: {'telefone': telefone});
    } on DioException catch (e) {
      throw ApiException(
        ApiException.messageFrom(e.response?.data,
            fallback: 'Não foi possível enviar o código. Tente novamente.'),
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Valida o código OTP e faz login (persiste a sessão). Lança [ApiException]
  /// (ex.: 401 código inválido/expirado) em falha.
  Future<void> verifyCode(String telefone, String codigo) async {
    try {
      final res = await _dio.post('/auth/verify-code',
          data: {'telefone': telefone, 'codigo': codigo});
      await persistSessionFromResponse(res);
    } on DioException catch (e) {
      throw ApiException(
        ApiException.messageFrom(e.response?.data,
            fallback: 'Código inválido ou expirado.'),
        statusCode: e.response?.statusCode,
      );
    }
  }

  // ── E-mail/senha (secundário) ───────────────────────────────────────────────

  /// Login por e-mail/senha. Retorna true em sucesso.
  Future<bool> login(String email, String senha) async {
    try {
      final res = await _dio.post('/auth/login', data: {'email': email, 'senha': senha});
      if (res.statusCode == 200 && res.data is Map && res.data['access_token'] != null) {
        await persistSessionFromResponse(res);
        return true;
      }
      return false;
    } on DioException {
      return false;
    }
  }

  /// Cadastro. Retorna null em sucesso, ou a mensagem de erro do servidor.
  Future<String?> register({
    required String nome,
    required String email,
    required String password,
    required String cpf,
    required String telefone,
  }) async {
    try {
      final res = await _dio.post('/auth/register', data: {
        'nome': nome,
        'email': email,
        'senha': password,
        'cpf': cpf,
        'telefone': telefone,
      });
      if ((res.statusCode == 200 || res.statusCode == 201) &&
          res.data is Map &&
          res.data['access_token'] != null) {
        await persistSessionFromResponse(res);
        return null;
      }
      return 'Cadastro realizado, mas não foi possível entrar automaticamente.';
    } on DioException catch (e) {
      return ApiException.messageFrom(e.response?.data,
          fallback: 'Erro ao criar conta. Tente novamente.');
    }
  }

  // ── Sessão ──────────────────────────────────────────────────────────────────

  Future<bool> isLoggedIn() => _session.hasToken();

  Future<String?> getToken() => _session.getToken();

  Future<void> logout() async {
    await _session.clear();
    final prefs = await SharedPreferences.getInstance();
    for (final k in ['user_id', 'user_nome', 'user_email', 'user_cpf', 'user_telefone']) {
      await prefs.remove(k);
    }
  }
}

