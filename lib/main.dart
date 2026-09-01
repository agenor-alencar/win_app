import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:provider/provider.dart';
import 'package:device_frame/device_frame.dart';
import 'models/product.dart';
import 'models/category.dart';
import 'models/cart.dart';
import 'models/favorites.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'services/auth_guard.dart';
import 'screens/login_screen.dart';
import 'screens/product_details_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/favorites_screen.dart';
import 'screens/addresses_screen.dart';
import 'screens/my_coupons_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // O app sempre abre na vitrine (pública). O login só é exigido
  // quando o usuário acessa uma funcionalidade restrita (AuthGuard).
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => Cart()),
        ChangeNotifierProvider(create: (_) => Favorites()),
      ],
      child: const PhoneFrameWrapper(
        child: WinMarketplaceApp(initialRoute: '/home'),
      ),
    ),
  );
}

/// Wrapper que exibe um frame de celular no desktop para simular aparência mobile.
class PhoneFrameWrapper extends StatelessWidget {
  final Widget child;
  const PhoneFrameWrapper({super.key, required this.child});

  bool get _isDesktop =>
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS;

  @override
  Widget build(BuildContext context) {
    if (!_isDesktop) return child;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF1A1A2E),
        body: Center(
          child: DeviceFrame(
            device: Devices.ios.iPhone13,
            isFrameVisible: true,
            orientation: Orientation.portrait,
            screen: child,
          ),
        ),
      ),
    );
  }
}

class WinMarketplaceApp extends StatelessWidget {
  final String initialRoute;
  const WinMarketplaceApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Win Marketplace',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF007AFF),
          primary: const Color(0xFF007AFF),
        ),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFBFBFB),
        fontFamily: 'Roboto',
      ),
      initialRoute: initialRoute,
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomePage(),
        '/cart': (context) => const CartScreen(),
        '/checkout': (context) => const CheckoutScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/orders': (context) => const OrdersScreen(),
        '/favorites': (context) => const FavoritesScreen(),
        '/addresses': (context) => const AddressesScreen(),
        '/coupons': (context) => const MyCouponsScreen(),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ApiService apiService = ApiService();
  final AuthService authService = AuthService();
  final TextEditingController _searchController = TextEditingController();
  
  late Future<List<Product>> _productsFuture;
  late Future<List<Category>> _categoriesFuture;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // Adiciona listener para atualizar o ícone de "X" na busca em tempo real
    _searchController.addListener(() {
      setState(() {});
    });
    _refreshData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refreshData() {
    setState(() {
      _productsFuture = apiService.getProducts();
      _categoriesFuture = apiService.getCategories();
      _isSearching = false;
      _searchController.clear();
    });
  }

  void _onSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      _refreshData();
      return;
    }

    setState(() {
      _isSearching = true;
      _productsFuture = apiService.searchProducts(query);
    });
    // Esconde o teclado após a busca
    FocusScope.of(context).unfocus();
  }

  IconData _getCategoryIcon(String name) {
    name = name.toLowerCase();
    if (name.contains('ferragem')) return Icons.build_rounded;
    if (name.contains('elétrica') || name.contains('eletrica')) return Icons.bolt_rounded;
    if (name.contains('limpeza')) return Icons.cleaning_services_rounded;
    if (name.contains('embalagem')) return Icons.inventory_2_rounded;
    if (name.contains('auto')) return Icons.directions_car_rounded;
    if (name.contains('promo')) return Icons.local_offer_rounded;
    if (name.contains('novidade')) return Icons.fiber_new_rounded;
    return Icons.grid_view_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('WIN', style: TextStyle(color: Color(0xFF007AFF), fontWeight: FontWeight.w900, fontSize: 26, letterSpacing: -1.5)),
            Text('Marketplace Local', style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w500)),
          ],
        ),
        actions: [
          _buildAppBarAction(Icons.favorite_border_rounded,
              () => AuthGuard.run(context, () => Navigator.pushNamed(context, '/favorites'))),
          Consumer<Cart>(
            builder: (_, cart, ch) => Badge(
              label: Text(cart.itemCount.toString()),
              isLabelVisible: cart.itemCount > 0,
              backgroundColor: Colors.redAccent,
              child: ch,
            ),
            child: _buildAppBarAction(Icons.shopping_cart_outlined,
                () => AuthGuard.run(context, () => Navigator.pushNamed(context, '/cart'))),
          ),
          _buildAppBarAction(Icons.person_outline_rounded,
              () => AuthGuard.run(context, () => Navigator.pushNamed(context, '/profile'))),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refreshData(),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search_rounded, color: Colors.grey.shade400),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onSubmitted: (_) => _onSearch(),
                                textInputAction: TextInputAction.search,
                                decoration: InputDecoration(
                                  hintText: 'Buscar produtos, lojas...',
                                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                                  border: InputBorder.none,
                                ),
                              ),
                            ),
                            if (_searchController.text.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18, color: Colors.grey),
                                onPressed: _refreshData,
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _onSearch,
                      child: Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFF007AFF),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: const Color(0xFF007AFF).withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: const Icon(Icons.search_rounded, color: Colors.white, size: 22), // Ícone alterado para Busca para clareza
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (!_isSearching)
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 110,
                  child: FutureBuilder<List<Category>>(
                    future: _categoriesFuture,
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox();
                      final categories = snapshot.data!;
                      return ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        itemCount: categories.length,
                        itemBuilder: (context, index) => _buildCategoryItem(categories[index]),
                      );
                    },
                  ),
                ),
              ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Text(
                  _isSearching ? 'Resultados da busca' : 'Produtos Disponíveis',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: FutureBuilder<List<Product>>(
                future: _productsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(40.0), child: CircularProgressIndicator())));
                  } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                    return SliverToBoxAdapter(child: _buildEmptyState());
                  }

                  final products = snapshot.data!;
                  return SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.68, crossAxisSpacing: 16, mainAxisSpacing: 16),
                    delegate: SliverChildBuilderDelegate((context, index) => _buildProductCard(products[index]), childCount: products.length),
                  );
                },
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBarAction(IconData icon, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(left: 8),
      decoration: BoxDecoration(color: Colors.grey.shade50, shape: BoxShape.circle),
      child: IconButton(onPressed: onTap, icon: Icon(icon, color: Colors.black87, size: 22)),
    );
  }

  Widget _buildCategoryItem(Category cat) {
    return Padding(
      padding: const EdgeInsets.only(right: 24),
      child: Column(
        children: [
          Container(
            height: 56, width: 56,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
            child: Icon(_getCategoryIcon(cat.nome), color: const Color(0xFF007AFF), size: 26),
          ),
          const SizedBox(height: 8),
          Text(cat.nome, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProductDetailsScreen(productId: product.id))),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5))]),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      child: (product.imagemUrl != null && product.imagemUrl!.isNotEmpty)
                          ? Image.network(product.imagemUrl!, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported_outlined, size: 32, color: Colors.black12))
                          : const Icon(Icons.image_outlined, size: 48, color: Colors.black12),
                    ),
                  ),
                  Positioned(
                    top: 12, right: 12,
                    child: Consumer<Favorites>(
                      builder: (context, favs, _) => GestureDetector(
                        onTap: () => AuthGuard.run(context, () => favs.toggleFavorite(product)),
                        child: Container(padding: const EdgeInsets.all(6), decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: Icon(favs.isFavorite(product.id) ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 16, color: favs.isFavorite(product.id) ? Colors.redAccent : Colors.black12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.nome, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, height: 1.2), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('R\$ ${product.preco.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF007AFF), fontWeight: FontWeight.w900, fontSize: 17)),
                      GestureDetector(
                        onTap: () => AuthGuard.run(context, () {
                          Provider.of<Cart>(context, listen: false).addItem(product, 1);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${product.nome} adicionado!'), duration: const Duration(seconds: 1)));
                        }),
                        child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: const Color(0xFF007AFF).withOpacity(0.08), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.add_shopping_cart_rounded, size: 16, color: Color(0xFF007AFF))),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded, size: 80, color: Colors.grey.shade200),
          const SizedBox(height: 20),
          Text(_isSearching ? 'Nenhum produto encontrado.' : 'Ops! Algo deu errado.', style: TextStyle(color: Colors.grey.shade400, fontSize: 16, fontWeight: FontWeight.bold)),
          TextButton(onPressed: _refreshData, child: const Text('Voltar ao início')),
        ],
      ),
    );
  }
}
