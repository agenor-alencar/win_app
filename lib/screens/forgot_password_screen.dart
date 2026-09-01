import 'package:flutter/material.dart';
import '../services/password_reset_service.dart';

/// Fluxo de recuperação de senha em dois passos:
/// 1) informar e-mail → backend envia um token por e-mail;
/// 2) informar o token recebido + nova senha.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  static const _blue = Color(0xFF007AFF);
  final _service = PasswordResetService();

  final _emailCtrl = TextEditingController();
  final _tokenCtrl = TextEditingController();
  final _senhaCtrl = TextEditingController();
  final _confirmaCtrl = TextEditingController();

  int _step = 0; // 0 = e-mail, 1 = token + nova senha
  bool _loading = false;
  bool _obscure = true;
  bool _obscureConfirm = true;
  String? _erro;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _tokenCtrl.dispose();
    _senhaCtrl.dispose();
    _confirmaCtrl.dispose();
    super.dispose();
  }

  Future<void> _enviarEmail() async {
    final email = _emailCtrl.text.trim();
    if (!email.contains('@')) {
      setState(() => _erro = 'Informe um e-mail válido.');
      return;
    }
    setState(() {
      _loading = true;
      _erro = null;
    });
    final erro = await _service.requestReset(email);
    if (!mounted) return;
    setState(() => _loading = false);
    if (erro == null) {
      setState(() => _step = 1);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Se o e-mail existir, você receberá um código para redefinir a senha.'),
          duration: Duration(seconds: 4),
        ),
      );
    } else {
      setState(() => _erro = erro);
    }
  }

  String? _validarSenha(String s) {
    if (s.length < 8) return 'A senha deve ter no mínimo 8 caracteres.';
    if (!RegExp(r'[a-z]').hasMatch(s)) return 'Inclua ao menos uma letra minúscula.';
    if (!RegExp(r'[A-Z]').hasMatch(s)) return 'Inclua ao menos uma letra maiúscula.';
    if (!RegExp(r'\d').hasMatch(s)) return 'Inclua ao menos um número.';
    return null;
  }

  Future<void> _confirmar() async {
    final token = _tokenCtrl.text.trim();
    final senha = _senhaCtrl.text;
    if (token.isEmpty) {
      setState(() => _erro = 'Informe o código recebido por e-mail.');
      return;
    }
    final erroSenha = _validarSenha(senha);
    if (erroSenha != null) {
      setState(() => _erro = erroSenha);
      return;
    }
    if (senha != _confirmaCtrl.text) {
      setState(() => _erro = 'As senhas não conferem.');
      return;
    }
    setState(() {
      _loading = true;
      _erro = null;
    });
    final erro = await _service.confirmReset(token: token, novaSenha: senha);
    if (!mounted) return;
    setState(() => _loading = false);
    if (erro == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Senha alterada com sucesso! Faça login com a nova senha.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } else {
      setState(() => _erro = erro);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Recuperar senha',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 18)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            Icon(_step == 0 ? Icons.lock_reset_rounded : Icons.mark_email_read_rounded,
                size: 56, color: _blue),
            const SizedBox(height: 16),
            Text(
              _step == 0 ? 'Esqueceu sua senha?' : 'Verifique seu e-mail',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              _step == 0
                  ? 'Informe o e-mail da sua conta. Enviaremos um código para você redefinir a senha.'
                  : 'Digite o código que enviamos para ${_emailCtrl.text.trim()} e escolha uma nova senha.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 28),

            if (_step == 0) ...[
              _label('E-mail'),
              _field(_emailCtrl, 'seu@email.com', keyboardType: TextInputType.emailAddress),
            ] else ...[
              _label('Código recebido'),
              _field(_tokenCtrl, 'Cole aqui o código do e-mail'),
              const SizedBox(height: 16),
              _label('Nova senha'),
              _field(_senhaCtrl, 'Mínimo 8 caracteres', obscure: _obscure,
                  suffix: _eye(_obscure, () => setState(() => _obscure = !_obscure))),
              const SizedBox(height: 16),
              _label('Confirmar nova senha'),
              _field(_confirmaCtrl, 'Repita a nova senha', obscure: _obscureConfirm,
                  suffix: _eye(_obscureConfirm, () => setState(() => _obscureConfirm = !_obscureConfirm))),
            ],

            if (_erro != null) ...[
              const SizedBox(height: 12),
              Text(_erro!, style: const TextStyle(color: Colors.red, fontSize: 13)),
            ],

            const SizedBox(height: 28),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _loading ? null : (_step == 0 ? _enviarEmail : _confirmar),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _blue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const SizedBox(
                        height: 22, width: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(_step == 0 ? 'Enviar código' : 'Redefinir senha',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            if (_step == 1) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: _loading ? null : _enviarEmail,
                child: const Text('Reenviar código', style: TextStyle(color: _blue)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      );

  Widget _field(TextEditingController c, String hint,
      {bool obscure = false, Widget? suffix, TextInputType? keyboardType}) {
    return TextField(
      controller: c,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        filled: true,
        fillColor: Colors.white,
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _blue, width: 1.5)),
      ),
    );
  }

  Widget _eye(bool obscure, VoidCallback onTap) => IconButton(
        icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            size: 20, color: Colors.grey),
        onPressed: onTap,
      );
}
