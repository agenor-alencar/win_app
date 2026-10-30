import 'package:dio/dio.dart';

import 'package:win_app/core/network/api_client.dart';
import 'package:win_app/core/network/api_exception.dart';

/// Redefinição de senha por e-mail — `POST /password-reset/request` e
/// `POST /password-reset/confirm`. (Mantém o nome `PasswordResetService` por
/// compatibilidade com a tela que já o consome.)
class PasswordResetService {
  final Dio _dio = ApiClient.instance.dio;

  /// Envia o e-mail de redefinição. Retorna null em sucesso, ou a mensagem de erro.
  Future<String?> requestReset(String email) async {
    try {
      await _dio.post('/password-reset/request', data: {'email': email});
      return null;
    } on DioException catch (e) {
      return ApiException.messageFrom(e.response?.data,
          fallback: 'Erro ao enviar e-mail. Tente novamente.');
    }
  }

  /// Confirma a redefinição com o token recebido. Retorna null em sucesso.
  Future<String?> confirmReset({
    required String token,
    required String novaSenha,
  }) async {
    try {
      await _dio.post('/password-reset/confirm', data: {'token': token, 'novaSenha': novaSenha});
      return null;
    } on DioException catch (e) {
      return ApiException.messageFrom(e.response?.data,
          fallback: 'Token inválido ou expirado.');
    }
  }
}
