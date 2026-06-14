class Product {
  final String id;
  final String nome;
  final String descricao;
  final double preco;
  final String? imagemUrl;
  final String? nomeLojista;
  final String? lojistaId;
  final double avaliacao;

  Product({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.preco,
    this.imagemUrl,
    this.nomeLojista,
    this.lojistaId,
    this.avaliacao = 0.0,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    // O backend retorna o lojista como objeto aninhado ({ id, nome }),
    // mas também aceitamos os campos achatados por compatibilidade.
    final lojista = json['lojista'];
    final lojistaId = lojista is Map
        ? lojista['id']?.toString()
        : json['lojistaId']?.toString();
    final nomeLojista = lojista is Map
        ? lojista['nome']
        : json['nomeLojista'];

    return Product(
      id: json['id']?.toString() ?? '',
      nome: json['nome'] ?? 'Sem nome',
      descricao: json['descricao'] ?? '',
      preco: (json['preco'] ?? 0).toDouble(),
      // Ajustado para o campo real do seu backend: imagemPrincipal
      imagemUrl: json['imagemPrincipal'],
      nomeLojista: nomeLojista,
      lojistaId: lojistaId,
      avaliacao: (json['avaliacao'] ?? 0.0).toDouble(),
    );
  }
}
