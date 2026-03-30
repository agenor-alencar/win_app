class Product {
  final String id;
  final String nome;
  final String descricao;
  final double preco;
  final String? imagemUrl;
  final String? nomeLojista;
  final double avaliacao;

  Product({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.preco,
    this.imagemUrl,
    this.nomeLojista,
    this.avaliacao = 0.0,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id']?.toString() ?? '',
      nome: json['nome'] ?? 'Sem nome',
      descricao: json['descricao'] ?? '',
      preco: (json['preco'] ?? 0).toDouble(),
      // Ajustado para o campo real do seu backend: imagemPrincipal
      imagemUrl: json['imagemPrincipal'],
      nomeLojista: json['nomeLojista'],
      avaliacao: (json['avaliacao'] ?? 0.0).toDouble(),
    );
  }
}
