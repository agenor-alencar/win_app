import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../models/cart.dart';
import '../models/favorites.dart';
import '../services/api_service.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String productId;

  const ProductDetailsScreen({super.key, required this.productId});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  final ApiService _apiService = ApiService();
  late Future<Product> _productFuture;
  late Future<List<Product>> _suggestionsFuture;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _productFuture = _apiService.getProductById(widget.productId);
      _suggestionsFuture = _apiService.getProducts();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.share_outlined, color: Colors.black), onPressed: () {}),
          // ÍCONE DE FAVORITO INTERATIVO
          FutureBuilder<Product>(
            future: _productFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              final product = snapshot.data!;
              return Consumer<Favorites>(
                builder: (context, favs, _) => IconButton(
                  icon: Icon(
                    favs.isFavorite(product.id) ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    color: favs.isFavorite(product.id) ? Colors.redAccent : Colors.black,
                  ),
                  onPressed: () => favs.toggleFavorite(product),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<Product>(
        future: _productFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Erro ao carregar detalhes: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('Produto não encontrado'));
          }

          final product = snapshot.data!;

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Hero(
                        tag: product.id,
                        child: Container(
                          height: MediaQuery.of(context).size.height * 0.4,
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFBFBFB),
                            borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                          ),
                          child: product.imagemUrl != null
                              ? Image.network(product.imagemUrl!, fit: BoxFit.contain)
                              : const Icon(Icons.image_outlined, size: 100, color: Colors.black12),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.nome,
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, height: 1.2, letterSpacing: -0.5),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'R\$ ${product.preco.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF007AFF),
                                  ),
                                ),
                                _buildQuantitySelector(),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _buildLojistaCard(product.nomeLojista),
                            const SizedBox(height: 32),
                            const Text('Descrição', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 12),
                            Text(
                              product.descricao.isNotEmpty ? product.descricao : 'Este produto oferece a qualidade e confiança que você busca no Win Marketplace.',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 15, height: 1.6),
                            ),
                            const SizedBox(height: 40),
                            const Text('Você também pode gostar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 16),
                            _buildSuggestionsList(),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _buildBottomAction(product),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLojistaCard(String? nomeLojista) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.storefront_rounded, color: Color(0xFF007AFF), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(nomeLojista ?? 'Lojista WIN', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const Text('Vendedor Verificado', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildSuggestionsList() {
    return SizedBox(
      height: 220,
      child: FutureBuilder<List<Product>>(
        future: _suggestionsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final products = snapshot.data!.where((p) => p.id != widget.productId).toList();
          
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final item = products[index];
              return GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => ProductDetailsScreen(productId: item.id)),
                  );
                },
                child: Container(
                  width: 150,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: Container(
                            color: const Color(0xFFFBFBFB),
                            width: double.infinity,
                            child: item.imagemUrl != null 
                              ? Image.network(item.imagemUrl!, fit: BoxFit.cover)
                              : const Icon(Icons.image_outlined, color: Colors.black12),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.nome, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text('R\$ ${item.preco.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF007AFF), fontWeight: FontWeight.w800, fontSize: 14)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildQuantitySelector() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          IconButton(onPressed: () => setState(() => _quantity > 1 ? _quantity-- : null), icon: const Icon(Icons.remove, size: 18)),
          Text('$_quantity', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          IconButton(onPressed: () => setState(() => _quantity++), icon: const Icon(Icons.add, size: 18)),
        ],
      ),
    );
  }

  Widget _buildBottomAction(Product product) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Provider.of<Cart>(context, listen: false).addItem(product, _quantity);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${product.nome} adicionado ao carrinho!'),
                  action: SnackBarAction(
                    label: 'VER',
                    onPressed: () => Navigator.pushNamed(context, '/cart'),
                  ),
                ),
              );
            },
            child: Container(
              height: 54,
              width: 54,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.shopping_cart_outlined, color: Color(0xFF007AFF)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                Provider.of<Cart>(context, listen: false).addItem(product, _quantity);
                Navigator.pushNamed(context, '/cart');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF007AFF),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 54),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Comprar Agora', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
