import 'package:win_app/core/config/app_environment.dart';
import 'package:win_app/main.dart';

/// Entrypoint do flavor DEV: `flutter run -t lib/main_dev.dart`.
void main() => bootstrap(flavor: Flavor.dev);
