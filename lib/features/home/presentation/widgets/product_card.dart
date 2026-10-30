import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:win_app/features/auth/auth_guard.dart';
import 'package:win_app/features/carrinho/domain/cart.dart';
import 'package:win_app/features/carrinho/domain/favorites.dart';
import 'package:win_app/features/catalogo/domain/product.dart';

/// Card de produto reutilizável da vitrine/busca.
///
/// Mostra imagem, nome, preço (com preço promocional riscando o cheio quando há
/// promoção), avaliação e sinalização de estoque quando o DTO informa. Tocar no
/// card dispara [onTap] (abre o detalhe). Favoritar e adicionar ao carrinho
/// passam pelo [AuthGuard] — a vitrine é pública, mas essas ações exigem login.
class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, required this.onTap});

  final Product product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final semEstoque = product.semEstoque;

    return Semantics(
      button: true,
      label: '${product.nome}, R\$ ${product.precoAtual.toStringAsFixed(2)}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _image(context, cs, semEstoque)),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.nome,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13, height: 1.2),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (product.avaliacao > 0) ...[
                      const SizedBox(height: 4),
                      _rating(cs),
                    ],
                    const SizedBox(height: 8),
                    _priceRow(context, cs, semEstoque),
                    if (product.estoqueBaixo && !semEstoque) ...[
                      const SizedBox(height: 6),
                      _stockHint(cs),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _image(BuildContext context, ColorScheme cs, bool semEstoque) {
    final hasImage = product.imagemUrl != null && product.imagemUrl!.isNotEmpty;
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          color: cs.surfaceContainerHighest,
          child: hasImage
              ? Image.network(
                  product.imagemUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                      Icons.image_not_supported_outlined,
                      size: 32,
                      color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
                  loadingBuilder: (ctx, child, progress) => progress == null
                      ? child
                      : Center(
                          child: SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: cs.primary),
                          ),
                        ),
                )
              : Icon(Icons.image_outlined,
                  size: 44, color: cs.onSurfaceVariant.withValues(alpha: 0.4)),
        ),
        if (product.hasPromo) Positioned(top: 10, left: 10, child: _promoBadge(cs)),
        if (semEstoque)
          Positioned.fill(
            child: Container(
              color: cs.scrim.withValues(alpha: 0.45),
              alignment: Alignment.center,
              child: _tag('Esgotado', cs.surface, cs.onSurface),
            ),
          ),
        Positioned(top: 8, right: 8, child: _favoriteButton(context, cs)),
      ],
    );
  }

  Widget _promoBadge(ColorScheme cs) {
    final pct = product.percentualDesconto;
    final label = (pct != null && pct > 0) ? '-${pct.round()}%' : 'Oferta';
    return _tag(label, cs.error, cs.onError);
  }

  Widget _tag(String text, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
        child: Text(text,
            style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w800)),
      );

  Widget _favoriteButton(BuildContext context, ColorScheme cs) {
    return Consumer<Favorites>(
      builder: (context, favs, _) {
        final isFav = favs.isFavorite(product.id);
        return Material(
          color: cs.surface,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => AuthGuard.run(context, () => favs.toggleFavorite(product)),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                size: 18,
                color: isFav ? cs.error : cs.onSurfaceVariant,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _rating(ColorScheme cs) {
    return Row(
      children: [
        Icon(Icons.star_rounded, size: 14, color: Colors.amber.shade600),
        const SizedBox(width: 2),
        Text(
          product.avaliacao.toStringAsFixed(1),
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant),
        ),
        if (product.quantidadeAvaliacoes > 0)
          Text(' (${product.quantidadeAvaliacoes})',
              style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant)),
      ],
    );
  }

  Widget _priceRow(BuildContext context, ColorScheme cs, bool semEstoque) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (product.hasPromo)
                Text(
                  'R\$ ${product.preco.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurfaceVariant,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              Text(
                'R\$ ${product.precoAtual.toStringAsFixed(2)}',
                style: TextStyle(
                    color: cs.primary, fontWeight: FontWeight.w900, fontSize: 16),
              ),
            ],
          ),
        ),
        _addToCartButton(context, cs, semEstoque),
      ],
    );
  }

  Widget _addToCartButton(BuildContext context, ColorScheme cs, bool semEstoque) {
    return Material(
      color: semEstoque
          ? cs.surfaceContainerHighest
          : cs.primary.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: semEstoque
            ? null
            : () => AuthGuard.run(context, () {
                  context.read<Cart>().addItem(product, 1);
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(SnackBar(
                      content: Text('${product.nome} adicionado ao carrinho'),
                      duration: const Duration(seconds: 1),
                    ));
                }),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            Icons.add_shopping_cart_rounded,
            size: 18,
            color: semEstoque ? cs.onSurfaceVariant : cs.primary,
          ),
        ),
      ),
    );
  }

  Widget _stockHint(ColorScheme cs) {
    return Row(
      children: [
        Icon(Icons.bolt_rounded, size: 13, color: cs.tertiary),
        const SizedBox(width: 2),
        Text(
          'Últimas ${product.estoque} un.',
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, color: cs.tertiary),
        ),
      ],
    );
  }
}
