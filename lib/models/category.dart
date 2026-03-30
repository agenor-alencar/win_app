class Category {
  final String id; // Alterado para String para suportar UUID
  final String nome;
  final String? iconeUrl;

  Category({required this.id, required this.nome, this.iconeUrl});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id']?.toString() ?? '',
      nome: json['nome'] ?? 'Sem nome',
      iconeUrl: json['iconeUrl'],
    );
  }
}
