class AppNotification {
  final String id;
  final String tipo;
  final String titulo;
  final String mensagem;
  bool lida;
  final DateTime? criadoEm;

  AppNotification({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.mensagem,
    this.lida = false,
    this.criadoEm,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id']?.toString() ?? '',
      tipo: json['tipo']?.toString() ?? '',
      titulo: json['titulo'] ?? '',
      mensagem: json['mensagem'] ?? '',
      lida: json['lida'] ?? false,
      criadoEm: json['criadoEm'] != null
          ? DateTime.tryParse('${json['criadoEm']}')
          : null,
    );
  }
}
