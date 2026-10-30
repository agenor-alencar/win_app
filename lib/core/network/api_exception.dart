/// Erro de API normalizado, com a mensagem amigável já extraída do corpo do
/// backend (campos `message`/`erro`/`error`).
class ApiException implements Exception {
  final int? statusCode;
  final String message;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() =>
      statusCode == null ? message : '($statusCode) $message';

  /// Extrai uma mensagem amigável de um corpo de erro JSON do backend.
  static String messageFrom(dynamic body, {String fallback = 'Erro inesperado.'}) {
    try {
      if (body is Map) {
        final m = body['message'] ?? body['erro'] ?? body['error'];
        if (m != null) return m.toString();
      }
      if (body is String && body.trim().isNotEmpty) return body;
    } catch (_) {}
    return fallback;
  }
}
