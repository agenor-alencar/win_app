import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_notification.dart';
import '../services/api_service.dart';

/// Tela de notificações do cliente: lista, marca como lida (ao tocar),
/// "marcar todas como lidas" e excluir (deslizando).
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const _blue = Color(0xFF007AFF);
  final ApiService _apiService = ApiService();

  String? _userId;
  bool _loading = true;
  List<AppNotification> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('user_id');
    if (_userId == null || _userId!.isEmpty) {
      setState(() {
        _items = [];
        _loading = false;
      });
      return;
    }
    final items = await _apiService.getNotifications(_userId!);
    if (!mounted) return;
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  int get _unread => _items.where((n) => !n.lida).length;

  Future<void> _marcarComoLida(AppNotification n) async {
    if (n.lida) return;
    setState(() => n.lida = true); // otimista
    final ok = await _apiService.markNotificationRead(n.id);
    if (!ok && mounted) {
      setState(() => n.lida = false); // reverte
    }
  }

  Future<void> _marcarTodas() async {
    if (_userId == null || _unread == 0) return;
    setState(() {
      for (final n in _items) {
        n.lida = true;
      }
    });
    await _apiService.markAllNotificationsRead(_userId!);
  }

  Future<void> _excluir(AppNotification n) async {
    final removida = n;
    setState(() => _items.remove(n));
    final ok = await _apiService.deleteNotification(n.id);
    if (!ok && mounted) {
      setState(() => _items.add(removida)); // reverte
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível excluir a notificação.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        title: const Text('Notificações', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_unread > 0)
            TextButton(
              onPressed: _marcarTodas,
              child: const Text('Marcar todas', style: TextStyle(color: _blue, fontSize: 13)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _items.isEmpty ? _buildEmptyState() : _buildList(),
            ),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _buildTile(_items[index]),
    );
  }

  Widget _buildTile(AppNotification n) {
    return Dismissible(
      key: ValueKey(n.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _excluir(n),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: () => _marcarComoLida(n),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: n.lida ? Colors.white : _blue.withOpacity(0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: n.lida ? Colors.grey.shade100 : _blue.withOpacity(0.25)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: _blue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_iconFor(n.tipo), color: _blue, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            n.titulo.isNotEmpty ? n.titulo : 'Notificação',
                            style: TextStyle(
                              fontWeight: n.lida ? FontWeight.w600 : FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        if (!n.lida)
                          Container(
                            width: 9, height: 9,
                            decoration: const BoxDecoration(color: _blue, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(n.mensagem,
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 13, height: 1.3)),
                    if (n.criadoEm != null) ...[
                      const SizedBox(height: 6),
                      Text(_formatData(n.criadoEm!),
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
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

  IconData _iconFor(String tipo) {
    final t = tipo.toUpperCase();
    if (t.contains('PEDIDO') || t.contains('ORDER')) return Icons.shopping_bag_outlined;
    if (t.contains('ENTREGA') || t.contains('DELIVERY')) return Icons.local_shipping_outlined;
    if (t.contains('PAGAMENTO') || t.contains('PIX')) return Icons.payments_outlined;
    if (t.contains('PROMO') || t.contains('CUPOM')) return Icons.local_offer_outlined;
    return Icons.notifications_outlined;
  }

  String _formatData(DateTime d) {
    final l = d.toLocal();
    final dd = l.day.toString().padLeft(2, '0');
    final mm = l.month.toString().padLeft(2, '0');
    final hh = l.hour.toString().padLeft(2, '0');
    final min = l.minute.toString().padLeft(2, '0');
    return '$dd/$mm ${hh}:$min';
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        const SizedBox(height: 140),
        Icon(Icons.notifications_none_rounded, size: 80, color: Colors.grey.shade200),
        const SizedBox(height: 20),
        Center(
          child: Text('Nenhuma notificação por aqui.',
              style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
