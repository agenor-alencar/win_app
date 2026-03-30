import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../models/order.dart';

class ApiService {
  static const String baseUrl = 'https://www.winmarketplace.com.br/api/v1';

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<Category>> getCategories() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/categoria/list/principais'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Category.fromJson(item)).toList();
      }
      return [];
    } catch (e) { return []; }
  }

  Future<List<Product>> getProducts() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/produtos'), headers: headers);
      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);
        List<dynamic> list;
        if (decodedData is List) {
          list = decodedData;
        } else if (decodedData is Map && decodedData.containsKey('content')) {
          list = decodedData['content'];
        } else { return []; }
        return list.map((item) => Product.fromJson(item)).toList();
      }
      return [];
    } catch (e) { return []; }
  }

  // MÉTODO PARA BUSCA REAL DE PRODUTOS
  Future<List<Product>> searchProducts(String query) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/produtos/buscar?q=$query'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final decodedData = json.decode(response.body);
        List<dynamic> list;
        if (decodedData is List) {
          list = decodedData;
        } else if (decodedData is Map && decodedData.containsKey('content')) {
          list = decodedData['content'];
        } else { return []; }
        return list.map((item) => Product.fromJson(item)).toList();
      }
      return [];
    } catch (e) { return []; }
  }

  Future<Product> getProductById(String id) async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/produtos/$id'), headers: headers);
    if (response.statusCode == 200) {
      return Product.fromJson(json.decode(response.body));
    } else {
      throw Exception('Falha ao carregar detalhes');
    }
  }

  Future<List<Order>> getUserOrders(String userId) async {
    final headers = await _getHeaders();
    final response = await http.get(Uri.parse('$baseUrl/pedidos/usuario/$userId'), headers: headers);
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((item) => Order.fromJson(item)).toList();
    } else { return []; }
  }

  Future<Map<String, dynamic>?> getAddressByCep(String cep) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/external/cep/$cep'));
      if (response.statusCode == 200) { return json.decode(response.body); }
      return null;
    } catch (e) { return null; }
  }

  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> orderData) async {
    final headers = await _getHeaders();
    final response = await http.post(Uri.parse('$baseUrl/pedidos'), headers: headers, body: jsonEncode(orderData));
    if (response.statusCode == 201 || response.statusCode == 200) { return json.decode(response.body); }
    else { throw Exception('Erro ao criar pedido: ${response.body}'); }
  }

  Future<Map<String, dynamic>> generatePix(String pedidoId) async {
    final headers = await _getHeaders();
    final url1 = '$baseUrl/pagamentos/pagarme/pix/$pedidoId';
    try {
      final response = await http.post(Uri.parse(url1), headers: headers);
      if (response.statusCode == 200) return json.decode(response.body);
      final url2 = '$baseUrl/pagamentos/pedido/$pedidoId/pix/obter-ou-recriar';
      final response2 = await http.post(Uri.parse(url2), headers: headers);
      if (response2.statusCode == 200) return json.decode(response2.body);
      throw Exception('Erro no servidor ao gerar PIX');
    } catch (e) { throw Exception('Falha ao gerar o pagamento PIX no servidor.'); }
  }
}
