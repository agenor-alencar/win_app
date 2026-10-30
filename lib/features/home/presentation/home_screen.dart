import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:win_app/features/auth/auth_guard.dart';
import 'package:win_app/features/carrinho/domain/cart.dart';
import 'package:win_app/features/catalogo/domain/product.dart';
import 'package:win_app/features/catalogo/presentation/product_details_screen.dart';
import 'package:win_app/features/home/presentation/home_provider.dart';
import 'package:win_app/features/home/presentation/widgets/category_rail.dart';
import 'package:win_app/features/home/presentation/widgets/home_search_bar.dart';
import 'package:win_app/features/home/presentation/widgets/nearby_stores_section.dart';
import 'package:win_app/features/home/presentation/widgets/product_grid.dart';

/// Home pública (primeira tela da Fase 1) — "navegar como visitante".
///
/// Vitrine de produtos + categorias + busca por nome. Nenhuma chamada
/// autenticada: ações restritas (carrinho, favoritos, notificações, perfil)
/// passam pelo [AuthGuard] e só pedem login quando tocadas. Consome o
/// [HomeProvider], que já trata skeleton / vazio / erro+retry por seção.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openProduct(Product product) {
    // A rota de detalhe completa evolui no bloco 2; por ora reusa a tela de
    // detalhe existente (recebe o id e carrega o resto).
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailsScreen(productId: product.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeProvider>();

    return Scaffold(
      appBar: _buildAppBar(context),
      body: RefreshIndicator(
        onRefresh: () => context.read<HomeProvider>().load(),
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            // Busca
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: HomeSearchBar(
                  controller: _searchController,
                  onSubmit: (q) {
                    FocusScope.of(context).unfocus();
                    context.read<HomeProvider>().search(q);
                  },
                  onClear: () {
                    _searchController.clear();
                    FocusScope.of(context).unfocus();
                    context.read<HomeProvider>().clearSearch();
                  },
                ),
              ),
            ),

            // Categorias e lojas próximas só aparecem no modo vitrine.
            if (!home.isSearching) ...[
              SliverToBoxAdapter(
                child: CategoryRail(
                  status: home.categoriesStatus,
                  categories: home.categories,
                  onRetry: () => context.read<HomeProvider>().loadCategories(),
                ),
              ),
              const SliverToBoxAdapter(child: NearbyStoresSection()),
            ],

            // Título da seção de produtos
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: Text(
                  home.isSearching
                      ? 'Resultados para "${home.query}"'
                      : 'Produtos disponíveis',
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                ),
              ),
            ),

            // Produtos (skeleton / vazio / erro+retry / grid)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: ProductGridSection(
                status: home.productsStatus,
                products: home.products,
                isSearching: home.isSearching,
                onRetry: () => context.read<HomeProvider>().retryProducts(),
                onProductTap: _openProduct,
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AppBar(
      centerTitle: false,
      titleSpacing: 16,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'WIN',
            style: TextStyle(
              color: cs.primary,
              fontWeight: FontWeight.w900,
              fontSize: 24,
              letterSpacing: -1.5,
            ),
          ),
          Text(
            'Marketplace Local',
            style: TextStyle(
                color: cs.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
      actions: [
        _action(context, Icons.notifications_none_rounded, 'Notificações',
            () => Navigator.pushNamed(context, '/notifications')),
        _action(context, Icons.favorite_border_rounded, 'Favoritos',
            () => Navigator.pushNamed(context, '/favorites')),
        Consumer<Cart>(
          builder: (_, cart, child) => Badge(
            label: Text('${cart.itemCount}'),
            isLabelVisible: cart.itemCount > 0,
            child: child,
          ),
          child: _action(context, Icons.shopping_cart_outlined, 'Carrinho',
              () => Navigator.pushNamed(context, '/cart')),
        ),
        _action(context, Icons.person_outline_rounded, 'Perfil',
            () => Navigator.pushNamed(context, '/profile')),
        const SizedBox(width: 4),
      ],
    );
  }

  /// Ação do app bar protegida por login (vitrine é pública; ação pede login).
  Widget _action(
      BuildContext context, IconData icon, String tooltip, VoidCallback action) {
    return IconButton(
      tooltip: tooltip,
      icon: Icon(icon),
      onPressed: () => AuthGuard.run(context, action),
    );
  }
}
