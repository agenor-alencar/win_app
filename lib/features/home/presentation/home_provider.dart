import 'package:flutter/foundation.dart' hide Category;

import 'package:win_app/features/catalogo/domain/category.dart';
import 'package:win_app/features/catalogo/domain/product.dart';
import 'package:win_app/features/home/data/home_repository.dart';

/// Estado de uma seção que carrega dados da rede.
enum LoadStatus { loading, ready, empty, error }

/// Estado da Home (vitrine pública): categorias principais, vitrine de produtos
/// e busca por nome. Sem nenhuma chamada autenticada — é a tela do visitante.
///
/// Cada seção tem seu próprio [LoadStatus] para que a tela mostre skeleton,
/// estado vazio caprichado ou erro amigável com retry, de forma independente
/// (uma falha nas categorias não derruba a vitrine, e vice-versa).
class HomeProvider extends ChangeNotifier {
  HomeProvider({HomeRepository? repository})
      : _repo = repository ?? HomeRepository();

  final HomeRepository _repo;

  // ── Categorias ──────────────────────────────────────────────────────────
  LoadStatus categoriesStatus = LoadStatus.loading;
  List<Category> categories = const [];

  // ── Produtos (vitrine OU resultados de busca) ─────────────────────────────
  LoadStatus productsStatus = LoadStatus.loading;
  List<Product> products = const [];

  // ── Busca ─────────────────────────────────────────────────────────────────
  String _query = '';
  String get query => _query;
  bool get isSearching => _query.isNotEmpty;

  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  /// Carga inicial (e pull-to-refresh): categorias + vitrine, em paralelo.
  /// Sempre volta ao modo vitrine (limpa a busca).
  Future<void> load() async {
    _query = '';
    await Future.wait([loadCategories(), loadShowcase()]);
  }

  Future<void> loadCategories() async {
    categoriesStatus = LoadStatus.loading;
    _safeNotify();
    try {
      final list = await _repo.fetchPrincipalCategories();
      categories = list;
      categoriesStatus = list.isEmpty ? LoadStatus.empty : LoadStatus.ready;
    } catch (_) {
      categoriesStatus = LoadStatus.error;
    }
    _safeNotify();
  }

  /// Carrega a vitrine (lista inicial de produtos).
  Future<void> loadShowcase() async {
    _query = '';
    productsStatus = LoadStatus.loading;
    _safeNotify();
    try {
      final list = await _repo.fetchShowcaseProducts();
      products = list;
      productsStatus = list.isEmpty ? LoadStatus.empty : LoadStatus.ready;
    } catch (_) {
      productsStatus = LoadStatus.error;
    }
    _safeNotify();
  }

  /// Busca por nome. Query vazia volta para a vitrine.
  Future<void> search(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      await loadShowcase();
      return;
    }
    _query = q;
    productsStatus = LoadStatus.loading;
    _safeNotify();
    try {
      final list = await _repo.searchProducts(q);
      // Ignora resultado de uma busca que já foi substituída por outra.
      if (_query != q) return;
      products = list;
      productsStatus = list.isEmpty ? LoadStatus.empty : LoadStatus.ready;
    } catch (_) {
      if (_query != q) return;
      productsStatus = LoadStatus.error;
    }
    _safeNotify();
  }

  /// Sai da busca e volta para a vitrine.
  Future<void> clearSearch() => loadShowcase();

  /// Re-tenta a seção de produtos no estado atual (busca ou vitrine).
  Future<void> retryProducts() =>
      isSearching ? search(_query) : loadShowcase();
}
