class Order {
  final String id;
  final String numeroPedido;
  final String status;
  final String statusPagamento;
  final double total;
  final DateTime? criadoEm;

  Order({
    required this.id,
    required this.numeroPedido,
    required this.status,
    required this.statusPagamento,
    required this.total,
    this.criadoEm,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? '',
      numeroPedido: json['numeroPedido'] ?? '',
      status: json['status'] ?? 'PENDENTE',
      statusPagamento: json['statusPagamento'] ?? 'PENDENTE',
      total: (json['total'] ?? 0.0).toDouble(),
      criadoEm: json['criadoEm'] != null ? DateTime.parse(json['criadoEm']) : null,
    );
  }
}
