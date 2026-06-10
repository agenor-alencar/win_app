class Review {
  final String id;
  final double nota;
  final String comentario;
  final String usuarioNome;
  final DateTime? createdAt;

  Review({
    required this.id,
    required this.nota,
    required this.comentario,
    required this.usuarioNome,
    this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id']?.toString() ?? '',
      nota: (json['nota'] ?? json['avaliacao'] ?? 0).toDouble(),
      comentario: json['comentario'] ?? json['descricao'] ?? '',
      usuarioNome: json['usuarioNome'] ?? json['nomeUsuario'] ?? 'Usuário',
      createdAt: json['criadoEm'] != null
          ? DateTime.tryParse(json['criadoEm'])
          : null,
    );
  }
}
