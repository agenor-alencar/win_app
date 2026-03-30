import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order.dart';
import '../services/api_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Order>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _loadOrders();
  }

  Future<List<Order>> _loadOrders() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id') ?? '';
    return _apiService.getUserOrders(userId);
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
      body: FutureBuilder<List<Order>>(
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
    );
  }

  Widget _buildOrderCard(Order order) {
    return Container(
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
              Text(
                'Pedido #${order.numeroPedido}',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
              ),
              _buildStatusBadge(order.statusPagamento),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Total: R\$ ${order.total.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF007AFF)),
          ),
          const SizedBox(height: 16),
          if (order.statusPagamento == 'PENDENTE')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Aqui podemos chamar o diálogo do PIX novamente
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF32BCAD).withOpacity(0.1),
                  foregroundColor: const Color(0xFF32BCAD),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('PAGAR COM PIX', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.orange;
    if (status == 'PAGO') color = Colors.green;
    if (status == 'CANCELADO') color = Colors.red;

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
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: Colors.grey.shade200),
          const SizedBox(height: 20),
          Text('Você ainda não tem pedidos.', style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
