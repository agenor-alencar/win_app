import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order.dart';
import '../services/api_service.dart';
import 'pix_payment_screen.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Order>> _ordersFuture;
  String? _payingId; // id do pedido cujo PIX está sendo gerado

  @override
  void initState() {
    super.initState();
    _ordersFuture = _loadOrders();
  }

  Future<List<Order>> _loadOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? '';
    final orders = await _apiService.getUserOrders(userId);
    // Pedidos cancelados ficam ocultos para não poluir a lista do cliente.
    return orders.where((o) => o.status != 'CANCELADO').toList();
  }

  void _refresh() {
    setState(() {
      _ordersFuture = _loadOrders();
    });
  }

  /// Remove (cancela) um pedido pendente da lista, após confirmação.
  Future<void> _removerPedido(Order order) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Remover pedido?',
            style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text(
            'O pedido #${order.numeroPedido} (não pago) será cancelado e sairá da sua lista.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('VOLTAR'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('REMOVER',
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmar != true) return;

    final ok = await _apiService.cancelOrder(order.id);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pedido removido da sua lista.')),
      );
      _refresh();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível remover o pedido. Tente novamente.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Gera (ou recupera) o PIX do pedido pendente e abre a tela de pagamento.
  Future<void> _pagarComPix(Order order) async {
    setState(() => _payingId = order.id);
    try {
      final prefs = await SharedPreferences.getInstance();
      final pixResponse = await _apiService.generatePix(
        order.id,
        nome: prefs.getString('user_nome') ?? '',
        email: prefs.getString('user_email') ?? '',
        cpf: prefs.getString('user_cpf') ?? '',
        telefone: prefs.getString('user_telefone') ?? '',
      );

      final billing = pixResponse['billing'] as Map<String, dynamic>?;
      final copiaECola = billing?['qrCode']?.toString();
      if (copiaECola == null || copiaECola.isEmpty) {
        final motivo = pixResponse['message'] ??
            pixResponse['error'] ??
            billing?['status'] ??
            pixResponse.toString();
        throw Exception('PIX não gerado: $motivo');
      }
      final amountCentavos = billing?['amount'];
      final valor = amountCentavos is num ? amountCentavos / 100.0 : order.total;
      final billingId = billing?['billingId']?.toString();
      final expiresAt = DateTime.tryParse(billing?['expiresAt']?.toString() ?? '');

      if (!mounted) return;
      setState(() => _payingId = null);
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PixPaymentScreen(
            pixCode: copiaECola,
            amount: valor,
            billingId: billingId,
            expiresAt: expiresAt,
          ),
        ),
      );
      // Ao voltar do pagamento, atualiza a lista (pode ter sido pago).
      _refresh();
    } catch (e) {
      if (!mounted) return;
      setState(() => _payingId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        title: const Text('Meus Pedidos', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        child: FutureBuilder<List<Order>>(
          future: _ordersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
              return _buildEmptyState();
            }

            final orders = snapshot.data!;
            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                return _buildOrderCard(orders[index]);
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _abrirDetalhe(Order order) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OrderDetailScreen(orderId: order.id),
      ),
    );
    // Ao voltar, atualiza (itens/pagamento podem ter mudado).
    _refresh();
  }

  Widget _buildOrderCard(Order order) {
    final pendente = order.statusPagamento == 'PENDENTE';
    return GestureDetector(
      onTap: () => _abrirDetalhe(order),
      child: Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Pedido #${order.numeroPedido}',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                ),
              ),
              _buildStatusBadge(order.statusPagamento),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Total: R\$ ${order.total.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF007AFF)),
          ),
          if (pendente) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _payingId != null ? null : () => _pagarComPix(order),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF32BCAD).withOpacity(0.1),
                      foregroundColor: const Color(0xFF32BCAD),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _payingId == order.id
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Color(0xFF32BCAD)),
                          )
                        : const Text('PAGAR COM PIX',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  tooltip: 'Remover pedido',
                  onPressed: () => _removerPedido(order),
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.redAccent.withOpacity(0.08),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.orange;
    if (status == 'APROVADO' || status == 'PAGO') color = Colors.green;
    if (status == 'CANCELADO' || status == 'RECUSADO') color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800),
      ),
    );
  }

  Widget _buildEmptyState() {
    // ListView para permitir o pull-to-refresh mesmo com a lista vazia.
    return ListView(
      children: [
        const SizedBox(height: 140),
        Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey.shade200),
        const SizedBox(height: 20),
        Center(
          child: Text('Você ainda não tem pedidos.',
              style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
