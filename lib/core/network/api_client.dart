import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:win_app/core/config/app_environment.dart';
import 'package:win_app/core/storage/secure_session_store.dart';

/// Cliente HTTP único do app (dio) com interceptors:
/// - anexa `Authorization: Bearer <token>` automaticamente (exceto rotas de auth públicas);
/// - no 401, tenta renovar a sessão via `/auth/refresh` (cookie) e refaz a chamada UMA vez;
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
          final alreadyRetried = e.requestOptions.extra['__retried'] == true;
          final isRefresh = e.requestOptions.path.contains('/auth/refresh');
          if (unauthorized && !alreadyRetried && !isRefresh) {
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
                return handler.next(err);
              }
            }
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
}

/// Persiste access token, expiração, cookie de refresh e (se presente) os dados
/// do usuário a partir de uma resposta de login/registro/OTP/refresh.
/// Compartilhado pelo interceptor de refresh e pelo `AuthRepository`.
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

  // Set-Cookie: refresh_token=...
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

  // Dados NÃO sensíveis do usuário ficam em shared_preferences (lidos pelas telas:
  // user_id/nome/email/cpf/telefone). Token/refresh ficam só no armazenamento seguro.
  if (data['usuario'] is Map) {
    final user = Map<String, dynamic>.from(data['usuario'] as Map);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', (user['id'] ?? '').toString());
    await prefs.setString('user_nome', (user['nome'] ?? '').toString());
    await prefs.setString('user_email', (user['email'] ?? '').toString());
    await prefs.setString('user_cpf', (user['cpf'] ?? '').toString());
    await prefs.setString('user_telefone', (user['telefone'] ?? '').toString());
  }
}
