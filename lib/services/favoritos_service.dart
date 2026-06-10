import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

/// Serviço de favoritos integrado à API Win Marketplace.
/// Sincroniza os favoritos do usuário com o backend via /api/v1/favoritos.
class FavoritosService {
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Retorna lista de IDs de produtos favoritos do usuário logado.
  Future<List<String>> getMeusFavoritos() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/favoritos/meus'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data
            .map((f) => (f['produtoId'] ?? f['produto']?['id'] ?? '').toString())
            .where((id) => id.isNotEmpty)
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Adiciona um produto aos favoritos.
  Future<bool> addFavorito(String produtoId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/favoritos'),
        headers: headers,
        body: jsonEncode({'produtoId': produtoId}),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (_) {
      return false;
    }
  }

  /// Remove um produto dos favoritos.
  Future<bool> removeFavorito(String produtoId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('${AppConfig.baseUrl}/favoritos/$produtoId'),
        headers: headers,
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  /// Verifica se um produto específico é favorito.
  Future<bool> isFavorito(String produtoId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/favoritos/verifica/$produtoId'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data == true || data['favorito'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
