class Delivery {
  final String id;
  final String statusEntrega;
  final String? statusDescricao;
  final String? nomeMotorista;
  final String? placaVeiculo;
  final String? contatoMotorista;
  final String? codigoEntrega; // PIN que o cliente mostra ao entregador
  final String? urlRastreamento;
  final DateTime? dataHoraEntrega;

  Delivery({
    required this.id,
    required this.statusEntrega,
    this.statusDescricao,
    this.nomeMotorista,
    this.placaVeiculo,
    this.contatoMotorista,
    this.codigoEntrega,
    this.urlRastreamento,
    this.dataHoraEntrega,
  });

  factory Delivery.fromJson(Map<String, dynamic> json) {
    return Delivery(
      id: json['id']?.toString() ?? '',
      statusEntrega: json['statusEntrega']?.toString() ?? '',
      statusDescricao: json['statusDescricao'],
      nomeMotorista: json['nomeMotorista'],
      placaVeiculo: json['placaVeiculo'],
      contatoMotorista: json['contatoMotorista'],
      codigoEntrega: json['codigoEntrega'],
      urlRastreamento: json['urlRastreamento'],
      dataHoraEntrega: json['dataHoraEntrega'] != null
          ? DateTime.tryParse('${json['dataHoraEntrega']}')
          : null,
    );
  }

  /// Entrega em estado terminal — não precisa mais fazer polling.
  bool get finalizada =>
      statusEntrega == 'ENTREGUE' || statusEntrega == 'CANCELADA';

  /// Progresso 0..1 para a barra de status (estimativa por estágio).
  double get progresso {
    switch (statusEntrega) {
      case 'AGUARDANDO_MOTORISTA':
        return 0.15;
      case 'MOTORISTA_A_CAMINHO_RETIRADA':
        return 0.4;
      case 'EM_TRANSITO':
        return 0.75;
      case 'ENTREGUE':
        return 1.0;
      case 'CANCELADA':
        return 0.0;
      default:
        return 0.1;
    }
  }

  /// Rótulo amigável (usa a descrição do backend quando houver).
  String get rotulo {
    if (statusDescricao != null && statusDescricao!.isNotEmpty) {
      return statusDescricao!;
    }
    switch (statusEntrega) {
      case 'AGUARDANDO_MOTORISTA':
        return 'Procurando entregador...';
      case 'MOTORISTA_A_CAMINHO_RETIRADA':
        return 'Entregador a caminho da loja';
      case 'EM_TRANSITO':
        return 'A caminho do seu endereço';
      case 'ENTREGUE':
        return 'Pedido entregue';
      case 'CANCELADA':
        return 'Entrega cancelada';
      default:
        return 'Preparando entrega';
    }
  }
}
