import 'package:flutter/material.dart';
import 'package:win_app/features/auth/presentation/otp_login_screen.dart';
import 'package:win_app/features/auth/data/auth_repository.dart';

/// Protege funcionalidades que exigem usuário autenticado.
///
/// A vitrine é pública; ao tocar em algo restrito (carrinho, favoritos,
/// perfil, compra), chame [ensureLoggedIn]: se o usuário não estiver logado,
/// a tela de login abre por cima e, após logar ou se cadastrar, ele volta
/// exatamente para onde estava.
class AuthGuard {
  static Future<bool> ensureLoggedIn(BuildContext context) async {
    if (await AuthRepository().isLoggedIn()) return true;
    if (!context.mounted) return false;
    // Login primário é por telefone/OTP; a tela de e-mail/senha é alcançável a
    // partir dela.
    final loggedIn = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const OtpLoginScreen(),
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
