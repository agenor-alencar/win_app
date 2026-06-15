class OrderItem {
  final String produtoId;
  final String produtoNome;
  final String? produtoImagem;
  int quantidade;
  final double precoUnitario;

  OrderItem({
    required this.produtoId,
    required this.produtoNome,
    this.produtoImagem,
    required this.quantidade,
    required this.precoUnitario,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      produtoId: json['produtoId']?.toString() ?? '',
      produtoNome: json['produtoNome'] ?? '',
      produtoImagem: json['produtoImagem'],
      quantidade: (json['quantidade'] ?? 1) is int
          ? json['quantidade']
          : int.tryParse('${json['quantidade']}') ?? 1,
      precoUnitario: (json['precoUnitario'] ?? 0).toDouble(),
    );
  }

  double get subtotal => precoUnitario * quantidade;
}

class Order {
  final String id;
  final String numeroPedido;
  final String status;
  final String statusPagamento;
  final double total;
  final double subtotal;
  final double frete;
  final String? lojistaId;
  final String? lojistaNome;
  final List<OrderItem> itens;
  final DateTime? criadoEm;

  Order({
    required this.id,
    required this.numeroPedido,
    required this.status,
    required this.statusPagamento,
    required this.total,
    this.subtotal = 0.0,
    this.frete = 0.0,
    this.lojistaId,
    this.lojistaNome,
    this.itens = const [],
    this.criadoEm,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final itensJson = json['itens'];
    return Order(
      id: json['id']?.toString() ?? '',
      numeroPedido: json['numeroPedido'] ?? '',
      status: json['status'] ?? 'PENDENTE',
      statusPagamento: json['statusPagamento'] ?? 'PENDENTE',
      total: (json['total'] ?? 0.0).toDouble(),
      subtotal: (json['subtotal'] ?? 0.0).toDouble(),
      frete: (json['frete'] ?? 0.0).toDouble(),
      lojistaId: json['lojistaId']?.toString(),
      lojistaNome: json['lojistaNome'],
      itens: itensJson is List
          ? itensJson.map((e) => OrderItem.fromJson(e)).toList()
          : const [],
      criadoEm:
          json['criadoEm'] != null ? DateTime.tryParse('${json['criadoEm']}') : null,
    );
  }
}
