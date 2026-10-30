import 'package:win_app/core/config/app_environment.dart';
import 'package:win_app/main.dart';

/// Entrypoint do flavor PROD: `flutter run -t lib/main_prod.dart`
/// (ou `flutter build apk -t lib/main_prod.dart`).
void main() => bootstrap(flavor: Flavor.prod);
