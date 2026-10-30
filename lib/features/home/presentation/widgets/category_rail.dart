import 'package:flutter/material.dart';

import 'package:win_app/core/theme/widgets/skeleton.dart';
import 'package:win_app/features/catalogo/domain/category.dart';
import 'package:win_app/features/home/presentation/home_provider.dart';

/// Trilho horizontal de categorias principais. Mostra skeleton enquanto carrega
/// e um retry discreto se falhar. Esconde-se (altura zero) quando vazio — a
/// vitrine de produtos continua sendo o foco.
class CategoryRail extends StatelessWidget {
  const CategoryRail({
    super.key,
    required this.status,
    required this.categories,
    required this.onRetry,
    this.onTap,
  });

  final LoadStatus status;
  final List<Category> categories;
  final VoidCallback onRetry;
  final ValueChanged<Category>? onTap;

  static const double _height = 104;

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case LoadStatus.loading:
        return _skeleton();
      case LoadStatus.error:
        return SizedBox(
          height: _height,
          child: Center(
            child: TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Recarregar categorias'),
            ),
          ),
        );
      case LoadStatus.empty:
        return const SizedBox.shrink();
      case LoadStatus.ready:
        return SizedBox(
          height: _height,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: categories.length,
            separatorBuilder: (_, _) => const SizedBox(width: 18),
            itemBuilder: (context, i) => _CategoryItem(
              category: categories[i],
              onTap: onTap == null ? null : () => onTap!(categories[i]),
            ),
          ),
        );
    }
  }

  Widget _skeleton() {
    return SizedBox(
      height: _height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: 6,
        separatorBuilder: (_, _) => const SizedBox(width: 18),
        itemBuilder: (_, _) => Column(
          children: const [
            Skeleton(height: 56, width: 56, borderRadius: BorderRadius.all(Radius.circular(16))),
            SizedBox(height: 8),
            Skeleton(height: 10, width: 48),
          ],
        ),
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  const _CategoryItem({required this.category, this.onTap});

  final Category category;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 64,
        child: Column(
          children: [
            Container(
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(_iconFor(category.nome), color: cs.primary, size: 26),
            ),
            const SizedBox(height: 6),
            Text(
              category.nome,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }

  /// Ícone aproximado por nome (o backend ainda não envia ícone próprio).
  IconData _iconFor(String name) {
    final n = name.toLowerCase();
    if (n.contains('ferragem')) return Icons.build_rounded;
    if (n.contains('elétric') || n.contains('eletric')) return Icons.bolt_rounded;
    if (n.contains('limpeza')) return Icons.cleaning_services_rounded;
    if (n.contains('embalagem')) return Icons.inventory_2_rounded;
    if (n.contains('auto')) return Icons.directions_car_rounded;
    if (n.contains('promo') || n.contains('oferta')) return Icons.local_offer_rounded;
    if (n.contains('novidade')) return Icons.fiber_new_rounded;
    if (n.contains('alimento') || n.contains('mercado')) return Icons.shopping_basket_rounded;
    if (n.contains('casa') || n.contains('lar')) return Icons.chair_rounded;
    return Icons.grid_view_rounded;
  }
}
