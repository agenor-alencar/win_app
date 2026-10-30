import 'package:flutter/material.dart';

import 'package:win_app/core/theme/widgets/skeleton.dart';
import 'package:win_app/features/catalogo/domain/product.dart';
import 'package:win_app/features/home/presentation/home_provider.dart';
import 'package:win_app/features/home/presentation/widgets/product_card.dart';

/// Seção de produtos da Home como **sliver** (usada dentro do CustomScrollView).
/// Resolve sozinha os quatro estados: skeleton, vazio caprichado, erro amigável
/// com retry e o grid de resultados. Deve ser colocada em `slivers:`.
class ProductGridSection extends StatelessWidget {
  const ProductGridSection({
    super.key,
    required this.status,
    required this.products,
    required this.isSearching,
    required this.onRetry,
    required this.onProductTap,
  });

  final LoadStatus status;
  final List<Product> products;
  final bool isSearching;
  final VoidCallback onRetry;
  final ValueChanged<Product> onProductTap;

  static const _gridDelegate = SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    childAspectRatio: 0.62,
    crossAxisSpacing: 14,
    mainAxisSpacing: 14,
  );

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case LoadStatus.loading:
        return SliverGrid(
          gridDelegate: _gridDelegate,
          delegate: SliverChildBuilderDelegate(
            (_, _) => const _CardSkeleton(),
            childCount: 6,
          ),
        );
      case LoadStatus.error:
        return SliverToBoxAdapter(
          child: _ErrorState(isSearching: isSearching, onRetry: onRetry),
        );
      case LoadStatus.empty:
        return SliverToBoxAdapter(
          child: _EmptyState(isSearching: isSearching, onRetry: onRetry),
        );
      case LoadStatus.ready:
        return SliverGrid(
          gridDelegate: _gridDelegate,
          delegate: SliverChildBuilderDelegate(
            (context, i) => ProductCard(
              product: products[i],
              onTap: () => onProductTap(products[i]),
            ),
            childCount: products.length,
          ),
        );
    }
  }
}

class _CardSkeleton extends StatelessWidget {
  const _CardSkeleton();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Expanded(
            child: Skeleton(height: double.infinity, borderRadius: BorderRadius.zero),
          ),
          Padding(
            padding: EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Skeleton(height: 12, width: double.infinity),
                SizedBox(height: 8),
                Skeleton(height: 12, width: 90),
                SizedBox(height: 14),
                Skeleton(height: 18, width: 70),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isSearching, required this.onRetry});

  final bool isSearching;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _CenteredMessage(
      icon: isSearching ? Icons.search_off_rounded : Icons.storefront_outlined,
      title: isSearching
          ? 'Nenhum produto encontrado'
          : 'Ainda não há produtos por aqui',
      subtitle: isSearching
          ? 'Tente outro termo ou confira a vitrine completa.'
          : 'Volte em breve — novidades estão chegando.',
      actionLabel: isSearching ? 'Ver vitrine' : 'Recarregar',
      onAction: onRetry,
      color: cs.onSurfaceVariant,
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.isSearching, required this.onRetry});

  final bool isSearching;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return _CenteredMessage(
      icon: Icons.cloud_off_rounded,
      title: 'Não foi possível carregar',
      subtitle:
          'Verifique sua conexão e tente novamente. Nada foi perdido — é só recarregar.',
      actionLabel: 'Tentar de novo',
      onAction: onRetry,
      color: cs.error,
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onAction,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onAction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      child: Column(
        children: [
          Icon(icon, size: 72, color: color.withValues(alpha: 0.6)),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w700, color: cs.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant, height: 1.4),
          ),
          const SizedBox(height: 20),
          FilledButton.tonalIcon(
            onPressed: onAction,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}
