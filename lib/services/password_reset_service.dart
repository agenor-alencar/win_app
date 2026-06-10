import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

/// Serviço para redefinição de senha via e-mail.
class PasswordResetService {
  /// Envia e-mail de redefinição de senha.
  /// Retorna null em caso de sucesso, ou mensagem de erro.
  Future<String?> requestReset(String email) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/password-reset/request'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        return null; // sucesso
      }
      try {
        final data = json.decode(response.body);
        return data['message'] ?? 'Erro ao enviar e-mail. Tente novamente.';
      } catch (_) {
        return 'Erro ao enviar e-mail (${response.statusCode}).';
      }
    } catch (_) {
      return 'Sem conexão com o servidor.';
    }
  }

  /// Confirma a redefinição de senha com o token recebido por e-mail.
  /// Retorna null em caso de sucesso, ou mensagem de erro.
  Future<String?> confirmReset({
    required String token,
    required String novaSenha,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/password-reset/confirm'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token, 'novaSenha': novaSenha}),
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        return null; // sucesso
      }
      try {
        final data = json.decode(response.body);
        return data['message'] ?? 'Token inválido ou expirado.';
      } catch (_) {
        return 'Erro ao redefinir senha (${response.statusCode}).';
      }
    } catch (_) {
      return 'Sem conexão com o servidor.';
    }
  }
}
