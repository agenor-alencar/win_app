class Address {
  final String id;
  final String logradouro;
  final String numero;
  final String complemento;
  final String bairro;
  final String cidade;
  final String estado;
  final String cep;
  final bool principal;

  Address({
    required this.id,
    required this.logradouro,
    required this.numero,
    this.complemento = '',
    required this.bairro,
    required this.cidade,
    required this.estado,
    required this.cep,
    this.principal = false,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id']?.toString() ?? '',
      logradouro: json['logradouro'] ?? '',
      numero: json['numero'] ?? '',
      complemento: json['complemento'] ?? '',
      bairro: json['bairro'] ?? '',
      cidade: json['cidade'] ?? json['localidade'] ?? '',
      estado: json['estado'] ?? json['uf'] ?? '',
      cep: json['cep'] ?? '',
      principal: json['principal'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'logradouro': logradouro,
        'numero': numero,
        'complemento': complemento,
        'bairro': bairro,
        'cidade': cidade,
        'estado': estado,
        'cep': cep,
        'principal': principal,
      };

  String get descricaoCompleta =>
      '$logradouro, $numero${complemento.isNotEmpty ? ', $complemento' : ''} — $bairro, $cidade/$estado';
}
