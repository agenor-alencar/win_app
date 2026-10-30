import 'package:dio/dio.dart';

import 'package:win_app/core/network/api_client.dart';
import 'package:win_app/features/catalogo/domain/category.dart';
import 'package:win_app/features/catalogo/domain/product.dart';

/// Fonte de dados da Home. Fala direto com o [ApiClient] (dio) e, de propósito,
/// **propaga o erro** (não devolve lista vazia no catch como o `ApiService`
/// genérico): assim o provider consegue distinguir "vazio" de "falha" e mostrar
/// mensagem amigável + retry.
///
/// Endpoints (todos públicos — "navegar como visitante", sem token):
/// - `GET /categoria/list/principais`
/// - `GET /produtos` (paginado: devolve `{ content: [...] }`)
/// - `GET /produtos/buscar?nome=` (o parâmetro é `nome`, não `q`)
class HomeRepository {
  HomeRepository({Dio? dio}) : _dio = dio ?? ApiClient.instance.dio;

  final Dio _dio;

  /// Normaliza respostas que podem vir como lista pura ou paginadas (`content`).
  List _asList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['content'] is List) return data['content'] as List;
    return const [];
  }

  List<T> _mapList<T>(dynamic data, T Function(Map<String, dynamic>) fromJson) =>
      _asList(data)
          .whereType<Map>()
          .map((e) => fromJson(Map<String, dynamic>.from(e)))
          .toList();

  Future<List<Category>> fetchPrincipalCategories() async {
    final res = await _dio.get('/categoria/list/principais');
    return _mapList(res.data, Category.fromJson);
  }

  Future<List<Product>> fetchShowcaseProducts() async {
    final res = await _dio.get('/produtos');
    return _mapList(res.data, Product.fromJson);
  }

  Future<List<Product>> searchProducts(String nome) async {
    final res = await _dio.get('/produtos/buscar', queryParameters: {'nome': nome});
    return _mapList(res.data, Product.fromJson);
  }
}
