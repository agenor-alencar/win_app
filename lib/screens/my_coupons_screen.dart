import 'package:flutter/material.dart';
import '../models/coupon.dart';
import '../services/api_service.dart';

/// Lista os cupons disponíveis do cliente (GET /cupom/meus).
/// Acessível pelo perfil; no checkout o cliente aplica o cupom.
class MyCouponsScreen extends StatefulWidget {
  const MyCouponsScreen({super.key});

  @override
  State<MyCouponsScreen> createState() => _MyCouponsScreenState();
}

class _MyCouponsScreenState extends State<MyCouponsScreen> {
  static const _blue = Color(0xFF007AFF);
  final ApiService _apiService = ApiService();
  late Future<List<Coupon>> _couponsFuture;

  @override
  void initState() {
    super.initState();
    _couponsFuture = _apiService.getMyCoupons();
  }

  Future<void> _refresh() async {
    setState(() {
      _couponsFuture = _apiService.getMyCoupons();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        title: const Text('Meus Cupons', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Coupon>>(
          future: _couponsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final coupons = snapshot.data ?? [];
            if (coupons.isEmpty) return _buildEmptyState();
            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: coupons.length,
              itemBuilder: (context, index) => _buildCouponCard(coupons[index]),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCouponCard(Coupon c) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          // Faixa lateral com o ícone
          Container(
            width: 64,
            height: 100,
            decoration: BoxDecoration(
              color: _blue.withOpacity(0.06),
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
            ),
            child: const Icon(Icons.local_offer_rounded, color: _blue, size: 28),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.codigo,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5)),
                  const SizedBox(height: 2),
                  Text(c.beneficio,
                      style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w700, fontSize: 13)),
                  if (c.descricao != null && c.descricao!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(c.descricao!,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  ],
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 12,
                    children: [
                      if (c.valorMinimoPedido > 0)
                        Text('Mín. R\$ ${c.valorMinimoPedido.toStringAsFixed(2)}',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                      if (c.dataFim != null)
                        Text('Válido até ${_formatDate(c.dataFim!)}',
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    return '$dd/$mm/${d.year}';
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        const SizedBox(height: 140),
        Icon(Icons.local_offer_outlined, size: 80, color: Colors.grey.shade200),
        const SizedBox(height: 20),
        Center(
          child: Text('Você não tem cupons disponíveis.',
              style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text('Cupons aparecem aqui quando você recebe um.',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
        ),
      ],
    );
  }
}
