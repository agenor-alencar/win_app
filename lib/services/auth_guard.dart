import 'package:flutter/material.dart';
import '../screens/login_screen.dart';
import 'auth_service.dart';

/// Protege funcionalidades que exigem usuário autenticado.
///
/// A vitrine é pública; ao tocar em algo restrito (carrinho, favoritos,
/// perfil, compra), chame [ensureLoggedIn]: se o usuário não estiver logado,
/// a tela de login abre por cima e, após logar ou se cadastrar, ele volta
/// exatamente para onde estava.
class AuthGuard {
  static Future<bool> ensureLoggedIn(BuildContext context) async {
    if (await AuthService().isLoggedIn()) return true;
    if (!context.mounted) return false;
    final loggedIn = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
        fullscreenDialog: true,
      ),
    );
    return loggedIn == true;
  }

  /// Executa [action] somente se o usuário estiver (ou acabar de ficar) logado.
  static Future<void> run(BuildContext context, VoidCallback action) async {
    if (await ensureLoggedIn(context)) {
      action();
    }
  }
}
