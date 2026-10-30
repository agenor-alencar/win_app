import 'package:dio/dio.dart';

import 'package:win_app/core/network/api_client.dart';
import 'package:win_app/core/network/api_exception.dart';
import 'package:win_app/features/catalogo/domain/product.dart';
import 'package:win_app/features/catalogo/domain/category.dart';
import 'package:win_app/features/catalogo/domain/review.dart';
import 'package:win_app/features/pedidos/domain/order.dart';
import 'package:win_app/features/pedidos/domain/delivery.dart';
import 'package:win_app/features/enderecos/domain/address.dart';
import 'package:win_app/features/checkout/domain/coupon.dart';
import 'package:win_app/features/perfil/domain/app_notification.dart';

/// Fachada de API do app, agora sobre o [ApiClient] (dio). O Bearer, o refresh
/// no 401 e o log (só em debug) ficam nos interceptors — aqui não há mais
/// montagem manual de header nem `ensureFreshToken`.
class ApiService {
  final Dio _dio = ApiClient.instance.dio;

  List _asList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['content'] is List) return data['content'] as List;
    return const [];
  }

  // ── USUÁRIO / PERFIL ────────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> getMyProfile() async {
    try {
      final res = await _dio.get('/auth/me');
      return res.data is Map ? Map<String, dynamic>.from(res.data as Map) : null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> updateUser(String userId, Map<String, dynamic> data) async {
    try {
      final res = await _dio.put('/usuario/update/$userId', data: data);
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── CATEGORIAS ──────────────────────────────────────────────────────────────
  Future<List<Category>> getCategories() async {
    try {
      final res = await _dio.get('/categoria/list/principais');
      return _asList(res.data).map((e) => Category.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // ── PRODUTOS ────────────────────────────────────────────────────────────────
  Future<List<Product>> getProducts() async {
    try {
      final res = await _dio.get('/produtos');
      return _asList(res.data).map((e) => Product.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Busca por nome — `GET /produtos/buscar?nome=` (o backend usa `nome`, não `q`).
  Future<List<Product>> searchProducts(String query) async {
    try {
      final res = await _dio.get('/produtos/buscar', queryParameters: {'nome': query});
      return _asList(res.data).map((e) => Product.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Sugestões da MESMA loja — `GET /produtos/lojista/{id}/sugestoes`.
  Future<List<Product>> getSuggestionsByLojista(
    String lojistaId, {
    List<String> excluir = const [],
    int limite = 6,
  }) async {
    if (lojistaId.isEmpty) return [];
    try {
      final res = await _dio.get(
        '/produtos/lojista/$lojistaId/sugestoes',
        queryParameters: {
          'limite': limite,
          if (excluir.isNotEmpty) 'excluirIds': excluir.where((e) => e.isNotEmpty).toList(),
        },
      );
      return _asList(res.data).map((e) => Product.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<Product> getProductById(String id) async {
    try {
      final res = await _dio.get('/produtos/$id');
      return Product.fromJson(res.data);
    } on DioException catch (e) {
      throw ApiException('Falha ao carregar detalhes do produto',
          statusCode: e.response?.statusCode);
    }
  }

  // ── AVALIAÇÕES ──────────────────────────────────────────────────────────────
  Future<List<Review>> getProductReviews(String produtoId) async {
    try {
      final res = await _dio.get('/avaliacoes-produtos/produto/$produtoId');
      return _asList(res.data).map((e) => Review.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> createReview({
    required String userId,
    required String produtoId,
    required int nota,
    required String comentario,
  }) async {
    try {
      await _dio.post('/avaliacoes-produtos/usuario/$userId', data: {
        'produtoId': produtoId,
        'nota': nota,
        'comentario': comentario,
      });
    } on DioException catch (e) {
      throw ApiException(ApiException.messageFrom(e.response?.data,
          fallback: 'Não foi possível enviar sua avaliação.'),
          statusCode: e.response?.statusCode);
    }
  }

  // ── ENDEREÇOS ───────────────────────────────────────────────────────────────
  Future<List<Address>> getAddressesByUser(String userId) async {
    try {
      final res = await _dio.get('/enderecos/usuario/$userId');
      return _asList(res.data).map((e) => Address.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<Address> createAddress(String userId, Address address) async {
    try {
      final res = await _dio.post('/enderecos/usuario/$userId', data: address.toJson());
      return Address.fromJson(res.data);
    } on DioException catch (e) {
      throw ApiException(ApiException.messageFrom(e.response?.data,
          fallback: 'Não foi possível salvar o endereço.'),
          statusCode: e.response?.statusCode);
    }
  }

  Future<bool> deleteAddress(String addressId) async {
    try {
      final res = await _dio.delete('/enderecos/$addressId');
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (_) {
      return false;
    }
  }

  Future<bool> setMainAddress(String addressId) async {
    try {
      final res = await _dio.patch('/enderecos/$addressId/principal');
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> getAddressByCep(String cep) async {
    try {
      final res = await _dio.get('/external/cep/$cep');
      return res.data is Map ? Map<String, dynamic>.from(res.data as Map) : null;
    } catch (_) {
      return null;
    }
  }

  // ── CUPONS ──────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> validateCoupon(String codigo) async {
    try {
      final res = await _dio.get('/cupom/validar/$codigo');
      return Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (e) {
      throw ApiException(ApiException.messageFrom(e.response?.data,
          fallback: 'Cupom inválido ou expirado'),
          statusCode: e.response?.statusCode);
    }
  }

  Future<Coupon> validateCouponTyped(String codigo) async =>
      Coupon.fromJson(await validateCoupon(codigo));

  Future<List<Coupon>> getMyCoupons() async {
    try {
      final res = await _dio.get('/cupom/meus');
      return _asList(res.data).map((e) => Coupon.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  // ── FRETE ───────────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> calcularFrete({
    required String lojistaId,
    required String enderecoEntregaId,
    double pesoTotalKg = 1.0,
  }) async {
    try {
      final res = await _dio.post('/fretes/calcular', data: {
        'lojistaId': lojistaId,
        'enderecoEntregaId': enderecoEntregaId,
        'pesoTotalKg': pesoTotalKg,
      });
      if (res.data is Map) return Map<String, dynamic>.from(res.data as Map);
      return {'sucesso': false, 'erro': 'Resposta inesperada do servidor.'};
    } on DioException catch (e) {
      // Erro de negócio (400) traz o corpo estruturado; repassa pra tela tratar.
      if (e.response?.data is Map) {
        return Map<String, dynamic>.from(e.response!.data as Map);
      }
      return {
        'sucesso': false,
        'codigoErro': 'UBER_INDISPONIVEL',
        'erro': 'Não foi possível calcular o frete agora. Tente novamente.',
      };
    }
  }

  Future<bool> isFreteGratisPrimeiraCompra(String userId) async {
    try {
      final res = await _dio.get('/pedidos/usuario/$userId/primeira-compra');
      return res.data is Map && res.data['freteGratis'] == true;
    } catch (_) {
      return false;
    }
  }

  // ── PEDIDOS ─────────────────────────────────────────────────────────────────
  Future<List<Order>> getUserOrders(String userId) async {
    try {
      final res = await _dio.get('/pedidos/usuario/$userId');
      return _asList(res.data).map((e) => Order.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<Order> getOrderById(String pedidoId) async {
    try {
      final res = await _dio.get('/pedidos/$pedidoId');
      return Order.fromJson(res.data);
    } on DioException catch (e) {
      throw ApiException('Erro ao carregar o pedido', statusCode: e.response?.statusCode);
    }
  }

  Future<Order> updateOrderItems(String pedidoId, List<OrderItem> itens) async {
    try {
      final res = await _dio.put('/pedidos/$pedidoId/itens', data: {
        'itens': itens
            .map((i) => {
                  'produtoId': i.produtoId,
                  'quantidade': i.quantidade,
                  'precoUnitario': i.precoUnitario,
                })
            .toList(),
      });
      return Order.fromJson(res.data);
    } on DioException catch (e) {
      throw ApiException(ApiException.messageFrom(e.response?.data,
          fallback: 'Não foi possível atualizar o pedido.'),
          statusCode: e.response?.statusCode);
    }
  }

  Future<Map<String, dynamic>> createOrder(Map<String, dynamic> orderData) async {
    try {
      final res = await _dio.post('/pedidos', data: orderData);
      return Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (e) {
      throw ApiException(ApiException.messageFrom(e.response?.data,
          fallback: 'Erro ao criar pedido.'),
          statusCode: e.response?.statusCode);
    }
  }

  Future<bool> cancelOrder(String pedidoId) async {
    try {
      final res = await _dio.patch('/pedidos/$pedidoId/cancelar');
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // ── PAGAMENTO ───────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> generatePix(
    String pedidoId, {
    required String nome,
    required String email,
    required String cpf,
    required String telefone,
  }) async {
    final body = {
      'nome': nome,
      'email': email,
      'cpf': cpf.replaceAll(RegExp(r'\D'), ''),
      'telefone': telefone.replaceAll(RegExp(r'\D'), ''),
    };
    int? s1, s2;
    String? b1, b2;
    try {
      final r1 = await _dio.post('/pagamentos/pagarme/pix/$pedidoId', data: body);
      if (r1.statusCode == 200) return Map<String, dynamic>.from(r1.data as Map);
      s1 = r1.statusCode;
    } on DioException catch (e) {
      s1 = e.response?.statusCode;
      b1 = ApiException.messageFrom(e.response?.data, fallback: '');
    }
    try {
      final r2 = await _dio.post('/pagamentos/pedido/$pedidoId/pix/obter-ou-recriar', data: body);
      if (r2.statusCode == 200) return Map<String, dynamic>.from(r2.data as Map);
      s2 = r2.statusCode;
    } on DioException catch (e) {
      s2 = e.response?.statusCode;
      b2 = ApiException.messageFrom(e.response?.data, fallback: '');
    }
    throw ApiException('Falha ao gerar PIX ($s1/$s2): ${b1 ?? ''} ${b2 ?? ''}'.trim());
  }

  Future<String?> checkPixStatus(String orderId) async {
    try {
      final res = await _dio.get('/pagamentos/$orderId/status');
      return res.data is Map ? res.data['status']?.toString() : null;
    } catch (_) {
      return null;
    }
  }

  // ── ENTREGA ───────────────────────────────────────────────────────────────
  Future<Delivery?> getDeliveryByOrder(String pedidoId) async {
    try {
      final res = await _dio.get('/entregas/pedido/$pedidoId');
      return res.statusCode == 200 ? Delivery.fromJson(res.data) : null;
    } catch (_) {
      return null;
    }
  }

  // ── NOTIFICAÇÕES ────────────────────────────────────────────────────────────
  Future<List<AppNotification>> getNotifications(String userId) async {
    try {
      final res = await _dio.get('/notificacao/list/usuario/$userId');
      return _asList(res.data).map((e) => AppNotification.fromJson(e)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<int> getUnreadNotificationsCount(String userId) async {
    try {
      final res = await _dio.get('/notificacao/count-nao-lidas/usuario/$userId');
      return int.tryParse(res.data.toString().trim()) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<bool> markNotificationRead(String id) async {
    try {
      final res = await _dio.patch('/notificacao/lida/$id');
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> markAllNotificationsRead(String userId) async {
    try {
      final res = await _dio.patch('/notificacao/todas-lidas/usuario/$userId');
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteNotification(String id) async {
    try {
      final res = await _dio.delete('/notificacao/delete/$id');
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (_) {
      return false;
    }
  }
}
