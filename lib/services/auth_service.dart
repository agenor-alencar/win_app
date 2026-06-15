import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'https://www.winmarketplace.com.br/api/v1';

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  /// Persiste o token de acesso, seu prazo de expiração e o cookie de refresh
  /// devolvido pelo servidor (Set-Cookie: refresh_token=...).
  Future<void> _persistSession(
      SharedPreferences prefs, Map<String, dynamic> data, http.Response res) async {
    final token = data['access_token'];
    if (token != null) await prefs.setString('jwt_token', token);

    final int expiresIn =
        (data['expires_in'] is num) ? (data['expires_in'] as num).toInt() : 1800;
    await prefs.setInt('token_expiry_ms',
        DateTime.now().millisecondsSinceEpoch + expiresIn * 1000);

    _saveRefreshCookie(prefs, res);
  }

  /// Extrai o valor do cookie refresh_token do cabeçalho Set-Cookie e o guarda.
  /// (httpOnly só restringe JS de navegador; um cliente HTTP pode lê-lo.)
  void _saveRefreshCookie(SharedPreferences prefs, http.Response res) {
    final setCookie = res.headers['set-cookie'];
    if (setCookie == null) return;
    final match = RegExp(r'refresh_token=([^;]+)').firstMatch(setCookie);
    if (match != null) {
      prefs.setString('refresh_token', match.group(1)!);
    }
  }

  /// Renova o access token usando o cookie de refresh — POST /auth/refresh.
  /// Endpoint público (não exige token válido). Rotaciona o cookie a cada uso.
  /// Retorna true se a sessão foi renovada.
  Future<bool> refreshSession() async {
    final prefs = await SharedPreferences.getInstance();
    final cookie = prefs.getString('refresh_token');
    if (cookie == null || cookie.isEmpty) return false;
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {
          'Content-Type': 'application/json',
          'Cookie': 'refresh_token=$cookie',
        },
      );
      if (res.statusCode == 200) {
        final data = json.decode(res.body);
        if (data['access_token'] != null) {
          await _persistSession(prefs, data, res);
          return true;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Renova o token se ele estiver expirado ou prestes a expirar (margem de 60s).
  Future<void> ensureFreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    final expiry = prefs.getInt('token_expiry_ms');
    if (token == null || expiry == null) return;
    if (DateTime.now().millisecondsSinceEpoch >= expiry - 60000) {
      await refreshSession();
    }
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
          await _persistSession(await SharedPreferences.getInstance(), data, response);

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

  /// Cria uma nova conta na API.
  /// Retorna null em caso de sucesso, ou uma mensagem de erro em caso de falha.
  Future<String?> register({
    required String nome,
    required String email,
    required String password,
    required String cpf,
    required String telefone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nome': nome,
          'email': email,
          'senha': password,
          'cpf': cpf,
          'telefone': telefone,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        final token = data['access_token'];

        if (token != null) {
          await saveToken(token);
          await _persistSession(await SharedPreferences.getInstance(), data, response);
          if (data['usuario'] != null) {
            final user = data['usuario'];
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('user_id', user['id']?.toString() ?? '');
            await prefs.setString('user_nome', user['nome'] ?? nome);
            await prefs.setString('user_email', user['email'] ?? email);
            await prefs.setString('user_cpf', user['cpf'] ?? cpf);
            await prefs.setString('user_telefone', user['telefone'] ?? telefone);
          }
          return null; // sucesso
        }
        return 'Cadastro realizado, mas não foi possível fazer login automático.';
      }

      // Tenta extrair mensagem de erro da API
      try {
        final data = json.decode(response.body);
        return data['message'] ?? data['erro'] ?? 'Erro ao criar conta. Tente novamente.';
      } catch (_) {
        return 'Erro ao criar conta (${response.statusCode}). Tente novamente.';
      }
    } catch (e) {
      return 'Sem conexão com o servidor. Verifique sua internet.';
    }
  }
}
