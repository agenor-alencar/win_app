/// Configuração de ambiente (flavors) do app.
///
/// Fonte ÚNICA da `baseUrl` — substitui a duplicação antiga
/// (`AppConfig.baseUrl` × `AuthService.baseUrl`). O flavor é resolvido por
/// `--dart-define=FLAVOR=dev|prod` (default `prod`) e pode ser fixado por um
/// entrypoint (`main_dev.dart` / `main_prod.dart`) via [applyFlavor].
enum Flavor { dev, prod }

class AppEnvironment {
  final Flavor flavor;
  final String baseUrl;

  const AppEnvironment({required this.flavor, required this.baseUrl});

  /// Dev: por padrão aponta para o backend local visto pelo emulador Android
  /// (`10.0.2.2` = localhost do host). Ajuste via `--dart-define` se precisar.
  static const AppEnvironment _dev = AppEnvironment(
    flavor: Flavor.dev,
    baseUrl: String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:8080/api/v1',
    ),
  );

  static const AppEnvironment _prod = AppEnvironment(
    flavor: Flavor.prod,
    baseUrl: String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'https://www.winmarketplace.com.br/api/v1',
    ),
  );

  static AppEnvironment _current = _resolveFromDefine();

  /// Ambiente ativo.
  static AppEnvironment get current => _current;

  /// Atalho estático para a base da API (fonte única).
  static String get apiBaseUrl => _current.baseUrl;

  /// Fixa o flavor em tempo de bootstrap (usado pelos entrypoints).
  static void applyFlavor(Flavor flavor) {
    _current = flavor == Flavor.dev ? _dev : _prod;
  }

  static AppEnvironment _resolveFromDefine() {
    const raw = String.fromEnvironment('FLAVOR', defaultValue: 'prod');
    return raw == 'dev' ? _dev : _prod;
  }
}
