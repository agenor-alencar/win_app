class Product {
  final String id;
  final String nome;
  final String descricao;

  /// Preço cheio (sempre presente). Quando há promoção vigente, [precoPromocional]
  /// vem preenchido e é o valor realmente cobrado — ver [precoAtual]/[hasPromo].
  final double preco;
  final double? precoPromocional;
  final double? percentualDesconto;

  /// Estoque disponível quando o DTO informa (listagem e busca trazem `estoque`).
  /// Null = backend não informou; não assumir esgotado nesse caso.
  final int? estoque;

  final String? imagemUrl;
  final String? nomeLojista;
  final String? lojistaId;
  final double avaliacao;
  final int quantidadeAvaliacoes;

  Product({
    required this.id,
    required this.nome,
    required this.descricao,
    required this.preco,
    this.precoPromocional,
    this.percentualDesconto,
    this.estoque,
    this.imagemUrl,
    this.nomeLojista,
    this.lojistaId,
    this.avaliacao = 0.0,
    this.quantidadeAvaliacoes = 0,
  });

  /// Há promoção vigente e o preço promocional é realmente menor que o cheio.
  bool get hasPromo =>
      precoPromocional != null && precoPromocional! > 0 && precoPromocional! < preco;

  /// Valor a exibir/cobrar: promocional quando vigente, senão o preço cheio.
  double get precoAtual => hasPromo ? precoPromocional! : preco;

  /// Backend informou estoque e ele está zerado.
  bool get semEstoque => estoque != null && estoque! <= 0;

  /// Poucas unidades (sinaliza urgência sem esconder o produto). Só quando o
  /// backend informou um estoque pequeno e positivo.
  bool get estoqueBaixo => estoque != null && estoque! > 0 && estoque! <= 5;

  factory Product.fromJson(Map<String, dynamic> json) {
    // O backend retorna o lojista ora como objeto aninhado ({ id, nome/nomeFantasia }),
    // ora com os campos achatados (nomeLojista/lojistaId) — aceitamos ambos.
    final lojista = json['lojista'];
    final lojistaId = lojista is Map
        ? lojista['id']?.toString()
        : json['lojistaId']?.toString();
    final nomeLojista = lojista is Map
        ? (lojista['nome'] ?? lojista['nomeFantasia'])
        : json['nomeLojista'];

    double? toDoubleOrNull(dynamic v) => v is num ? v.toDouble() : null;

    return Product(
      id: json['id']?.toString() ?? '',
      nome: json['nome'] ?? 'Sem nome',
      descricao: json['descricao'] ?? '',
      preco: (json['preco'] ?? 0).toDouble(),
      precoPromocional: toDoubleOrNull(json['precoPromocional']),
      percentualDesconto: toDoubleOrNull(json['percentualDesconto']),
      estoque: json['estoque'] is num ? (json['estoque'] as num).toInt() : null,
      // Campo real do backend: imagemPrincipal.
      imagemUrl: json['imagemPrincipal'] ?? json['imagemUrl'],
      nomeLojista: nomeLojista,
      lojistaId: lojistaId,
      avaliacao: (json['avaliacao'] ?? 0.0).toDouble(),
      quantidadeAvaliacoes:
          json['quantidadeAvaliacoes'] is num ? (json['quantidadeAvaliacoes'] as num).toInt() : 0,
    );
  }
}
