class Coupon {
  final String codigo;
  final String? descricao;
  final String tipoDesconto; // ex.: FRETE_GRATIS
  final double valorDesconto;
  final double valorMinimoPedido;
  final DateTime? dataFim;

  Coupon({
    required this.codigo,
    this.descricao,
    required this.tipoDesconto,
    this.valorDesconto = 0,
    this.valorMinimoPedido = 0,
    this.dataFim,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      codigo: json['codigo']?.toString() ?? '',
      descricao: json['descricao'],
      tipoDesconto: json['tipoDesconto']?.toString() ?? '',
      valorDesconto: (json['valorDesconto'] ?? 0).toDouble(),
      valorMinimoPedido: (json['valorMinimoPedido'] ?? 0).toDouble(),
      dataFim: json['dataFim'] != null
          ? DateTime.tryParse('${json['dataFim']}')
          : null,
    );
  }

  /// Cupom que zera o frete do pedido.
  bool get isFreteGratis => tipoDesconto == 'FRETE_GRATIS';

  /// Rótulo curto do benefício, para exibir ao cliente.
  String get beneficio => isFreteGratis
      ? 'Frete grátis'
      : (valorDesconto > 0 ? 'R\$ ${valorDesconto.toStringAsFixed(2)} de desconto' : 'Desconto');
}
