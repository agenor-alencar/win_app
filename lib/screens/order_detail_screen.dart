import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import 'pix_payment_screen.dart';

/// Detalhe do pedido. Para pedidos PENDENTES (não pagos), o cliente pode
/// editar os itens (quantidade, remover, adicionar sugestões da mesma loja)
/// e finalizar o pagamento. Pedidos já pagos/avançados são somente leitura.
class OrderDetailScreen extends StatefulWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  static const _blue = Color(0xFF007AFF);
  final _apiService = ApiService();

  Order? _order;
  List<OrderItem> _itens = [];
  Future<List<Product>> _suggestionsFuture = Future.value(const []);
  bool _loading = true;
  bool _saving = false;
  bool _paying = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final order = await _apiService.getOrderById(widget.orderId);
      if (!mounted) return;
      setState(() {
        _order = order;
        _itens = order.itens
            .map((i) => OrderItem(
                  produtoId: i.produtoId,
                  produtoNome: i.produtoNome,
                  produtoImagem: i.produtoImagem,
                  quantidade: i.quantidade,
                  precoUnitario: i.precoUnitario,
                ))
            .toList();
        _loading = false;
      });
      _loadSuggestions();
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _loadSuggestions() {
    final lojistaId = _order?.lojistaId;
    if (lojistaId == null || lojistaId.isEmpty) return;
    setState(() {
      _suggestionsFuture = _apiService.getSuggestionsByLojista(
        lojistaId,
        excluir: _itens.map((i) => i.produtoId).toList(),
      );
    });
  }

  bool get _editable =>
      _order != null &&
      _order!.statusPagamento == 'PENDENTE' &&
      _order!.status == 'PENDENTE';

  bool get _dirty {
    if (_order == null) return false;
    final orig = {for (final i in _order!.itens) i.produtoId: i.quantidade};
    if (orig.length != _itens.length) return true;
    for (final i in _itens) {
      if (orig[i.produtoId] != i.quantidade) return true;
    }
    return false;
  }

  double get _subtotal =>
      _itens.fold(0.0, (t, i) => t + i.subtotal);
  double get _frete => _order?.frete ?? 0.0;
  double get _total => _subtotal + _frete;

  void _inc(OrderItem item) => setState(() => item.quantidade++);
  void _dec(OrderItem item) {
    setState(() {
      if (item.quantidade > 1) {
        item.quantidade--;
      } else {
        _itens.remove(item);
      }
    });
  }

  void _remove(OrderItem item) => setState(() => _itens.remove(item));

  void _addSuggestion(Product p) {
    setState(() {
      final existente = _itens.where((i) => i.produtoId == p.id).toList();
      if (existente.isNotEmpty) {
        existente.first.quantidade++;
      } else {
        _itens.add(OrderItem(
          produtoId: p.id,
          produtoNome: p.nome,
          produtoImagem: p.imagemUrl,
          quantidade: 1,
          precoUnitario: p.preco,
        ));
      }
    });
    _loadSuggestions(); // remove o adicionado das sugestões
  }

  Future<bool> _save() async {
    if (_itens.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O pedido precisa ter ao menos um item.')),
      );
      return false;
    }
    setState(() => _saving = true);
    try {
      final updated = await _apiService.updateOrderItems(widget.orderId, _itens);
      if (!mounted) return false;
      setState(() {
        _order = updated;
        _itens = updated.itens
            .map((i) => OrderItem(
                  produtoId: i.produtoId,
                  produtoNome: i.produtoNome,
                  produtoImagem: i.produtoImagem,
                  quantidade: i.quantidade,
                  precoUnitario: i.precoUnitario,
                ))
            .toList();
        _saving = false;
      });
      _loadSuggestions();
      return true;
    } catch (e) {
      if (!mounted) return false;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $e'), backgroundColor: Colors.red),
      );
      return false;
    }
  }

  Future<void> _pagar() async {
    // Garante que as alterações estão salvas antes de gerar o PIX.
    if (_dirty) {
      final ok = await _save();
      if (!ok) return;
    }
    setState(() => _paying = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final pixResponse = await _apiService.generatePix(
        widget.orderId,
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
      final valor = amountCentavos is num ? amountCentavos / 100.0 : _total;
      final billingId = billing?['billingId']?.toString();
      final expiresAt = DateTime.tryParse(billing?['expiresAt']?.toString() ?? '');

      if (!mounted) return;
      setState(() => _paying = false);
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
      _load(); // ao voltar, recarrega (pode ter sido pago)
    } catch (e) {
      if (!mounted) return;
      setState(() => _paying = false);
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
        title: const Text('Detalhe do Pedido',
            style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _order == null
              ? const Center(child: Text('Pedido não encontrado'))
              : _buildBody(),
      bottomNavigationBar: (_loading || _order == null) ? null : _buildBottomBar(),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text('Pedido #${_order!.numeroPedido}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ),
              _statusBadge(_order!.statusPagamento),
            ],
          ),
          if (_order!.lojistaNome != null) ...[
            const SizedBox(height: 4),
            Text(_order!.lojistaNome!,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          ],
          const SizedBox(height: 20),

          const Text('Itens', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          ..._itens.map(_buildItemTile),

          if (!_editable)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Este pedido não pode mais ser editado.',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
              ),
            ),

          if (_editable) ...[
            const SizedBox(height: 24),
            const Text('Adicione mais desta loja',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            _buildSuggestions(),
          ],

          const SizedBox(height: 24),
          _buildSummary(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildItemTile(OrderItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 56,
              height: 56,
              color: const Color(0xFFF8F9FA),
              child: item.produtoImagem != null && item.produtoImagem!.isNotEmpty
                  ? Image.network(item.produtoImagem!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.image_outlined, color: Colors.black12))
                  : const Icon(Icons.image_outlined, color: Colors.black12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.produtoNome,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('R\$ ${item.precoUnitario.toStringAsFixed(2)}',
                    style: const TextStyle(color: _blue, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          if (_editable)
            _buildQtyStepper(item)
          else
            Text('x${item.quantidade}',
                style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildQtyStepper(OrderItem item) {
    return Row(
      children: [
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: () => _dec(item),
          icon: Icon(item.quantidade > 1
              ? Icons.remove_circle_outline
              : Icons.delete_outline_rounded),
          color: item.quantidade > 1 ? Colors.black54 : Colors.redAccent,
        ),
        Text('${item.quantidade}',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
        IconButton(
          visualDensity: VisualDensity.compact,
          onPressed: () => _inc(item),
          icon: const Icon(Icons.add_circle_outline),
          color: _blue,
        ),
      ],
    );
  }

  Widget _buildSuggestions() {
    return SizedBox(
      height: 210,
      child: FutureBuilder<List<Product>>(
        future: _suggestionsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final produtos = snapshot.data!;
          if (produtos.isEmpty) {
            return Center(
              child: Text('Sem mais produtos desta loja.',
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
            );
          }
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: produtos.length,
            itemBuilder: (context, index) {
              final p = produtos[index];
              return Container(
                width: 150,
                margin: const EdgeInsets.only(right: 12),
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
                          child: p.imagemUrl != null && p.imagemUrl!.isNotEmpty
                              ? Image.network(p.imagemUrl!, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.image_outlined, color: Colors.black12))
                              : const Icon(Icons.image_outlined, color: Colors.black12),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.nome,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text('R\$ ${p.preco.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        color: _blue, fontWeight: FontWeight.w800, fontSize: 13),
                                    overflow: TextOverflow.ellipsis),
                              ),
                              GestureDetector(
                                onTap: () => _addSuggestion(p),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: _blue.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.add, size: 18, color: _blue),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          _summaryRow('Subtotal', 'R\$ ${_subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: 10),
          _summaryRow('Frete',
              _frete == 0 ? 'Grátis' : 'R\$ ${_frete.toStringAsFixed(2)}'),
          const Divider(height: 28),
          _summaryRow('Total', 'R\$ ${_total.toStringAsFixed(2)}', isTotal: true),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: isTotal ? 18 : 14,
                fontWeight: isTotal ? FontWeight.w900 : FontWeight.w500)),
        Text(value,
            style: TextStyle(
                fontSize: isTotal ? 20 : 14,
                fontWeight: isTotal ? FontWeight.w900 : FontWeight.w700,
                color: isTotal ? _blue : Colors.black)),
      ],
    );
  }

  Widget? _buildBottomBar() {
    if (!_editable) return null;
    final busy = _saving || _paying;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Row(
          children: [
            if (_dirty) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: busy ? null : _save,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _blue,
                    side: const BorderSide(color: _blue),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 18, width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Salvar', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: busy ? null : _pagar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _paying
                    ? const SizedBox(
                        height: 18, width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_dirty ? 'SALVAR E PAGAR' : 'PAGAR COM PIX',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color color = Colors.orange;
    if (status == 'APROVADO' || status == 'PAGO') color = Colors.green;
    if (status == 'CANCELADO' || status == 'RECUSADO') color = Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(status,
          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800)),
    );
  }
}
