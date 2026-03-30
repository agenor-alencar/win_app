class DataModel {
  final int id;
  final String title;
  final String description;

  DataModel({required this.id, required this.title, required this.description});

  // Converte o JSON vindo do Spring Boot para o objeto Dart
  factory DataModel.fromJson(Map<String, dynamic> json) {
    return DataModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? json['nome'] ?? 'Sem título',
      description: json['description'] ?? json['descricao'] ?? '',
    );
  }
}
