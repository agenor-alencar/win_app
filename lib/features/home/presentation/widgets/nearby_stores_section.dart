import 'package:flutter/material.dart';

/// Seção "Lojas perto de você".
///
/// TODO(fase-1): o backend `win` ainda **não** expõe um endpoint de lojas por
/// localização (não há rota de proximidade em LojaController/LojistaController;
/// o que existe é `GET /produtos?cep=` filtrando produtos pelo raio de entrega).
/// Enquanto não houver endpoint de lojas por geolocalização, esta seção fica
/// preparada e marcada — NÃO inventar endpoint. Quando existir, trocar este
/// placeholder por uma lista horizontal de lojas (reusar o padrão de card).
///
/// Visualmente discreta para não competir com a vitrine; some sem quebrar o
/// layout quando/ se decidirmos escondê-la via [visible].
class NearbyStoresSection extends StatelessWidget {
  const NearbyStoresSection({super.key, this.visible = true});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.storefront_rounded, size: 20, color: cs.primary),
              const SizedBox(width: 8),
              Text(
                'Lojas perto de você',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800, color: cs.onSurface),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                Icon(Icons.near_me_outlined, color: cs.onSurfaceVariant),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Em breve',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, color: cs.onSurface),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Vamos mostrar as lojas mais próximas de onde você está.',
                        style: TextStyle(
                            fontSize: 13, color: cs.onSurfaceVariant, height: 1.3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
