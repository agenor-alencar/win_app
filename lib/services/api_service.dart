import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../models/order.dart';
import '../models/address.dart';
import '../models/review.dart';

class ApiService {
  // ─── AUTH HEADER ────────────────────────────────────────────────────────────
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ─── USUÁRIO / PERFIL ────────────────────────────────────────────────────────
  /// Retorna os dados do usuário autenticado — GET /auth/me
  Future<Map<String, dynamic>?> getMyProfile() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/auth/me'),
        headers: headers,
      );
      if (response.statusCode == 200) return json.decode(response.body);
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Atualiza dados do usuário — PUT /usuario/update/{id}
  Future<bool> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('${AppConfig.baseUrl}/usuario/update/$userId'),
        headers: headers,
        body: jsonEncode(data),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ─── CATEGORIAS ──────────────────────────────────────────────────────────────
  Future<List<Category>> getCategories() async {
    try {
      final response = await http.get(
          Uri.parse('${AppConfig.baseUrl}/categoria/list/principais'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Category.fromJson(item)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // ─── PRODUTOS ────────────────────────────────────────────────────────────────
  Future<List<Product>> getProducts() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
          Uri.parse('${AppConfig.baseUrl}/produtos'),
          headers: headers);
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final list = decoded is List
            ? decoded
            : (decoded is Map && decoded.containsKey('content'))
                ? decoded['content']
                : [];
        return (list as List).map((item) => Product.fromJson(item)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<List<Product>> searchProducts(String query) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/produtos/buscar?q=$query'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final list = decoded is List
            ? decoded
            : (decoded is Map && decoded.containsKey('content'))
                ? decoded['content']
                : [];
        return (list as List).map((item) => Product.fromJson(item)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<Product> getProductById(String id) async {
    final headers = await _getHeaders();
    final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/produtos/$id'),
        headers: headers);
    if (response.statusCode == 200) {
      return Product.fromJson(json.decode(response.body));
    }
    throw Exception('Falha ao carregar detalhes do produto');
  }

  // ─── AVALIAÇÕES ──────────────────────────────────────────────────────────────
  /// Retorna avaliações de um produto — GET /avaliacoes-produtos/produto/{id}
  Future<List<Review>> getProductReviews(String produtoId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/avaliacoes-produtos/produto/$produtoId'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Review.fromJson(item)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  // ─── ENDEREÇOS ───────────────────────────────────────────────────────────────
  /// Retorna endereços salvos do usuário — GET /enderecos/usuario/{id}
  Future<List<Address>> getAddressesByUser(String userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/enderecos/usuario/$userId'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Address.fromJson(item)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Cria um novo endereço para o usuário — POST /enderecos/usuario/{id}
  Future<Address?> createAddress(String userId, Address address) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/enderecos/usuario/$userId'),
        headers: headers,
        body: jsonEncode(address.toJson()),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Address.fromJson(json.decode(response.body));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Exclui um endereço do usuário — DELETE /enderecos/{id}
  Future<bool> deleteAddress(String addressId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('${AppConfig.baseUrl}/enderecos/$addressId'),
        headers: headers,
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  /// Define um endereço como principal — PATCH /enderecos/{id}/principal
  Future<bool> setMainAddress(String addressId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.patch(
        Uri.parse('${AppConfig.baseUrl}/enderecos/$addressId/principal'),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Lookup de CEP — GET /external/cep/{cep}
  Future<Map<String, dynamic>?> getAddressByCep(String cep) async {
    try {
      final response =
          await http.get(Uri.parse('${AppConfig.baseUrl}/external/cep/$cep'));
      if (response.statusCode == 200) return json.decode(response.body);
      return null;
    } catch (_) {
      return null;
    }
  }

  // ─── CUPONS ──────────────────────────────────────────────────────────────────
  /// Valida um cupom de desconto — GET /cupom/validar/{codigo}
  /// Retorna dados do cupom (ex: {"desconto": 10.0, "tipo": "PERCENTUAL"})
  /// ou lança Exception se inválido.
  Future<Map<String, dynamic>> validateCoupon(String codigo) async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('${AppConfig.baseUrl}/cupom/validar/$codigo'),
      headers: headers,
    );
    if (response.statusCode == 200) return json.decode(response.body);
    throw Exception('Cupom inválido ou expirado');
  }

  // ─── FRETE ───────────────────────────────────────────────────────────────────
  /// Calcula o frete dinâmico (Uber Direct) — POST /fretes/calcular.
  /// Exige usuário autenticado e um endereço já salvo (UUID).
  /// Retorna o corpo do FreteResponseDTO; em erro de negócio o backend
  /// devolve `sucesso: false` com `erro`/`codigoErro` (status 400), que
  /// repassamos para a tela tratar — nunca inventamos um valor de frete.
  Future<Map<String, dynamic>> calcularFrete({
    required String lojistaId,
    required String enderecoEntregaId,
    double pesoTotalKg = 1.0,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/fretes/calcular'),
        headers: headers,
        body: jsonEncode({
          'lojistaId': lojistaId,
          'enderecoEntregaId': enderecoEntregaId,
          'pesoTotalKg': pesoTotalKg,
        }),
      );
      final decoded = json.decode(response.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'sucesso': false, 'erro': 'Resposta inesperada do servidor.'};
    } catch (_) {
      return {
        'sucesso': false,
        'codigoErro': 'UBER_INDISPONIVEL',
        'erro': 'Não foi possível calcular o frete agora. Tente novamente.',
      };
    }
  }

  /// Verifica se é a primeira compra do usuário (frete grátis) —
  /// GET /pedidos/usuario/{id}/primeira-compra.
  Future<bool> isFreteGratisPrimeiraCompra(String userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/pedidos/usuario/$userId/primeira-compra'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['freteGratis'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  // ─── PEDIDOS ─────────────────────────────────────────────────────────────────
  Future<List<Order>> getUserOrders(String userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
          Uri.parse('${AppConfig.baseUrl}/pedidos/usuario/$userId'),
          headers: headers);
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Order.fromJson(item)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> createOrder(
      Map<String, dynamic> orderData) async {
    final headers = await _getHeaders();
    final response = await http.post(
        Uri.parse('${AppConfig.baseUrl}/pedidos'),
        headers: headers,
        body: jsonEncode(orderData));
    if (response.statusCode == 201 || response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Erro ao criar pedido: ${response.body}');
  }

  /// Cancela um pedido — PATCH /pedidos/{id}/cancelar
  Future<bool> cancelOrder(String pedidoId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.patch(
        Uri.parse('${AppConfig.baseUrl}/pedidos/$pedidoId/cancelar'),
        headers: headers,
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ─── PAGAMENTO ───────────────────────────────────────────────────────────────
  /// Gera o pagamento PIX (Pagar.me) para um pedido.
  /// Os dois endpoints exigem os dados do cliente no corpo da requisição
  /// ({nome, cpf, telefone, email}) — sem isso o backend devolve 400.
  Future<Map<String, dynamic>> generatePix(
    String pedidoId, {
    required String nome,
    required String email,
    required String cpf,
    required String telefone,
  }) async {
    final headers = await _getHeaders();
    final body = jsonEncode({
      'nome': nome,
      'email': email,
      'cpf': cpf.replaceAll(RegExp(r'\D'), ''),
      'telefone': telefone.replaceAll(RegExp(r'\D'), ''),
    });
    // Tenta endpoint primário, depois fallback
    try {
      final r1 = await http.post(
          Uri.parse('${AppConfig.baseUrl}/pagamentos/pagarme/pix/$pedidoId'),
          headers: headers,
          body: body);
      if (r1.statusCode == 200) return json.decode(r1.body);

      final r2 = await http.post(
          Uri.parse(
              '${AppConfig.baseUrl}/pagamentos/pedido/$pedidoId/pix/obter-ou-recriar'),
          headers: headers,
          body: body);
      if (r2.statusCode == 200) return json.decode(r2.body);

      throw Exception('Erro no servidor ao gerar PIX (${r1.statusCode}/${r2.statusCode})');
    } catch (e) {
      throw Exception('Falha ao gerar o pagamento PIX: $e');
    }
  }

  /// Consulta o status de um pagamento PIX — GET /pagamentos/{orderId}/status.
  /// Retorna a string de status (ex.: "paid", "pending") ou null em erro.
  Future<String?> checkPixStatus(String orderId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('${AppConfig.baseUrl}/pagamentos/$orderId/status'),
        headers: headers,
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['status']?.toString();
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
