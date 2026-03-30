import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'https://www.winmarketplace.com.br/api/v1';

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'senha': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['access_token'];
        
        if (token != null) {
          await saveToken(token);
          
          if (data['usuario'] != null) {
            final user = data['usuario'];
            final prefs = await SharedPreferences.getInstance();
            // Salvando tudo para o auto-preenchimento e para o checkout
            await prefs.setString('user_id', user['id'] ?? '');
            await prefs.setString('user_nome', user['nome'] ?? '');
            await prefs.setString('user_email', user['email'] ?? '');
            await prefs.setString('user_cpf', user['cpf'] ?? '');
            await prefs.setString('user_telefone', user['telefone'] ?? '');
          }
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }
}
