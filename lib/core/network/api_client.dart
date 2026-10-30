import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:win_app/core/app_navigator.dart';
import 'package:win_app/core/config/app_environment.dart';
import 'package:win_app/core/storage/secure_session_store.dart';

/// Cliente HTTP único do app (dio) com interceptors:
/// - anexa `Authorization: Bearer <token>` automaticamente (exceto rotas de auth públicas);
/// - no 401, tenta renovar a sessão via `/auth/refresh` (cookie) e refaz a chamada UMA vez;
/// - se o refresh falhar DE VEZ (sem cookie, refresh 401, ou o retry ainda deu 401),
///   encerra a sessão (secure storage + prefs legados) e roteia para o login — evita
///   ficar "logado" com um token inválido;
/// - loga apenas em debug e somente método/caminho/status (nunca token/PII).
class ApiClient {
  ApiClient._() {
    _dio = Dio(BaseOptions(
      baseUrl: AppEnvironment.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      contentType: Headers.jsonContentType,
    ));
    _dio.interceptors.add(_authInterceptor());
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        request: false,
        requestHeader: false,
        requestBody: false,
        responseHeader: false,
        responseBody: false,
        error: true,
        logPrint: (o) => debugPrint('[api] $o'),
      ));
    }
  }

  static final ApiClient instance = ApiClient._();

  late final Dio _dio;
  Dio get dio => _dio;

  final SecureSessionStore _session = SecureSessionStore.instance;
  bool _refreshing = false;
  bool _handlingExpiry = false;

  static const _publicAuthPaths = [
    '/auth/login',
    '/auth/register',
    '/auth/request-code',
    '/auth/verify-code',
    '/auth/enviar-sms',
    '/auth/validar-sms',
    '/auth/refresh',
    '/password-reset',
    '/external/',
    '/categoria/',
  ];

  bool _isPublic(String path) => _publicAuthPaths.any(path.contains);

  Interceptor _authInterceptor() => InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (!_isPublic(options.path)) {
            final token = await _session.getToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
        onError: (e, handler) async {
          final unauthorized = e.response?.statusCode == 401;
          final hadAuth = e.requestOptions.headers.containsKey('Authorization');
          final alreadyRetried = e.requestOptions.extra['__retried'] == true;
          final isRefresh = e.requestOptions.path.contains('/auth/refresh');

          // Só tratamos 401 de requisições AUTENTICADAS (um 401 de login/otp é erro
          // de credencial, não expiração de sessão).
          if (unauthorized && hadAuth && !isRefresh) {
            if (!alreadyRetried) {
              final ok = await _tryRefresh();
              if (ok) {
                try {
                  final req = e.requestOptions;
                  req.extra['__retried'] = true;
                  final token = await _session.getToken();
                  if (token != null) req.headers['Authorization'] = 'Bearer $token';
                  final response = await _dio.fetch(req);
                  return handler.resolve(response);
                } on DioException catch (err) {
                  // Retry ainda deu erro: se foi 401 de novo, cai no encerramento abaixo.
                  if (err.response?.statusCode == 401) {
                    await _handleSessionExpired();
                  }
                  return handler.next(err);
                }
              }
            }
            // Refresh falhou de vez (sem cookie / refresh inválido / retry 401).
            await _handleSessionExpired();
          }
          handler.next(e);
        },
      );

  /// Renova o access token via cookie de refresh. Usa um Dio "cru" (sem
  /// interceptors) para não recorrer. Protegido contra chamadas concorrentes.
  Future<bool> _tryRefresh() async {
    if (_refreshing) return false;
    _refreshing = true;
    try {
      final cookie = await _session.getRefreshToken();
      if (cookie == null || cookie.isEmpty) return false;
      final bare = Dio(BaseOptions(
        baseUrl: AppEnvironment.apiBaseUrl,
        contentType: Headers.jsonContentType,
      ));
      final res = await bare.post(
        '/auth/refresh',
        options: Options(headers: {'Cookie': 'refresh_token=$cookie'}),
      );
      final data = res.data;
      if (res.statusCode == 200 && data is Map && data['access_token'] != null) {
        await persistSessionFromResponse(res);
        return true;
      }
      return false;
    } catch (_) {
      return false;
    } finally {
      _refreshing = false;
    }
  }

  /// Sessão expirada em definitivo: limpa segredos + perfil (secure storage) e
  /// prefs legados, e manda o usuário para o login. Idempotente por ciclo.
  Future<void> _handleSessionExpired() async {
    if (_handlingExpiry) return;
    _handlingExpiry = true;
    try {
      await _session.clear();
      await clearLegacySessionPrefs();
      final nav = rootNavigatorKey.currentState;
      nav?.pushNamedAndRemoveUntil('/login-otp', (route) => false);
    } finally {
      _handlingExpiry = false;
    }
  }
}

/// Persiste access token, expiração, cookie de refresh e (se presente) o perfil
/// do usuário — TUDO no armazenamento seguro. Compartilhado pelo interceptor de
/// refresh e pelo `AuthRepository`.
Future<void> persistSessionFromResponse(Response res) async {
  final session = SecureSessionStore.instance;
  final data = res.data;
  if (data is! Map) return;

  final token = data['access_token'];
  if (token is String && token.isNotEmpty) {
    await session.setToken(token);
  }

  final expiresIn = (data['expires_in'] is num) ? (data['expires_in'] as num).toInt() : 1800;
  await session.setTokenExpiryMs(DateTime.now().millisecondsSinceEpoch + expiresIn * 1000);

  final setCookie = res.headers.map['set-cookie'];
  if (setCookie != null) {
    for (final c in setCookie) {
      final m = RegExp(r'refresh_token=([^;]+)').firstMatch(c);
      if (m != null) {
        await session.setRefreshToken(m.group(1)!);
        break;
      }
    }
  }

  // Perfil (PII) agora no armazenamento seguro — não mais em shared_preferences.
  if (data['usuario'] is Map) {
    await session.saveUser(Map<String, dynamic>.from(data['usuario'] as Map));
  }
}

/// Remove valores legados de sessão/perfil que versões anteriores gravavam em
/// `shared_preferences` em texto puro. Best-effort.
Future<void> clearLegacySessionPrefs() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    for (final k in [
      'user_id', 'user_nome', 'user_email', 'user_cpf', 'user_telefone',
      'jwt_token', 'refresh_token', 'token_expiry_ms',
    ]) {
      await prefs.remove(k);
    }
  } catch (_) {}
}
