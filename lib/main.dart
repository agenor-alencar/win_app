import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:device_frame/device_frame.dart';
import 'package:win_app/core/app_navigator.dart';
import 'package:win_app/features/carrinho/domain/cart.dart';
import 'package:win_app/features/carrinho/domain/favorites.dart';
import 'package:win_app/features/auth/presentation/login_screen.dart';
import 'package:win_app/features/carrinho/presentation/cart_screen.dart';
import 'package:win_app/features/checkout/presentation/checkout_screen.dart';
import 'package:win_app/features/perfil/presentation/profile_screen.dart';
import 'package:win_app/features/pedidos/presentation/orders_screen.dart';
import 'package:win_app/features/carrinho/presentation/favorites_screen.dart';
import 'package:win_app/features/enderecos/presentation/addresses_screen.dart';
import 'package:win_app/features/perfil/presentation/my_coupons_screen.dart';
import 'package:win_app/features/perfil/presentation/notifications_screen.dart';
import 'package:win_app/features/auth/presentation/otp_login_screen.dart';
import 'package:win_app/features/home/presentation/home_screen.dart';
import 'package:win_app/features/home/presentation/home_provider.dart';
import 'package:win_app/core/config/app_environment.dart';
import 'package:win_app/core/theme/app_theme.dart';

/// Entrypoint padrão (flavor vem do `--dart-define=FLAVOR`, default prod).
/// Veja `main_dev.dart` / `main_prod.dart` para fixar o flavor.
void main() => bootstrap();

/// Inicialização compartilhada pelos entrypoints de flavor.
void bootstrap({Flavor? flavor}) {
  WidgetsFlutterBinding.ensureInitialized();
  if (flavor != null) AppEnvironment.applyFlavor(flavor);

  // O app sempre abre na vitrine (pública). O login só é exigido
  // quando o usuário acessa uma funcionalidade restrita (AuthGuard).
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => Cart()),
        ChangeNotifierProvider(create: (_) => Favorites()),
        ChangeNotifierProvider(create: (_) => HomeProvider()..load()),
      ],
      child: const PhoneFrameWrapper(
        child: WinMarketplaceApp(initialRoute: '/home'),
      ),
    ),
  );
}

/// Wrapper que exibe um frame de celular no desktop para simular aparência mobile.
class PhoneFrameWrapper extends StatelessWidget {
  final Widget child;
  const PhoneFrameWrapper({super.key, required this.child});

  bool get _isDesktop =>
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS;

  @override
  Widget build(BuildContext context) {
    if (!_isDesktop) return child;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF1A1A2E),
        body: Center(
          child: DeviceFrame(
            device: Devices.ios.iPhone13,
            isFrameVisible: true,
            orientation: Orientation.portrait,
            screen: child,
          ),
        ),
      ),
    );
  }
}

class WinMarketplaceApp extends StatelessWidget {
  final String initialRoute;
  const WinMarketplaceApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Win Marketplace',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      initialRoute: initialRoute,
      routes: {
        '/login': (context) => const LoginScreen(),
        '/login-otp': (context) => const OtpLoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/cart': (context) => const CartScreen(),
        '/checkout': (context) => const CheckoutScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/orders': (context) => const OrdersScreen(),
        '/favorites': (context) => const FavoritesScreen(),
        '/addresses': (context) => const AddressesScreen(),
        '/coupons': (context) => const MyCouponsScreen(),
        '/notifications': (context) => const NotificationsScreen(),
      },
    );
  }
}
