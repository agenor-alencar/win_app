import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:win_app/core/network/api_exception.dart';
import 'package:win_app/core/theme/widgets/primary_button.dart';
import 'package:win_app/features/auth/data/auth_repository.dart';
import 'package:win_app/features/auth/presentation/login_screen.dart';

/// Login primário por telefone (OTP): telefone → código → entra.
/// Usa `POST /auth/request-code` e `POST /auth/verify-code`.
/// Fecha com `true` quando o login conclui (compatível com o AuthGuard).
class OtpLoginScreen extends StatefulWidget {
  const OtpLoginScreen({super.key});

  @override
  State<OtpLoginScreen> createState() => _OtpLoginScreenState();
}

enum _Step { telefone, codigo }

class _OtpLoginScreenState extends State<OtpLoginScreen> {
  final _auth = AuthRepository();
  final _telCtrl = TextEditingController();
  final _codigoCtrl = TextEditingController();

  _Step _step = _Step.telefone;
  bool _loading = false;

  @override
  void dispose() {
    _telCtrl.dispose();
    _codigoCtrl.dispose();
    super.dispose();
  }

  /// Normaliza para E.164 BR: só dígitos, com DDI +55 quando vier sem.
  String _normalizarTelefone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('55')) return '+$digits';
    if (digits.length == 10 || digits.length == 11) return '+55$digits';
    return '+$digits';
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.redAccent : null,
    ));
  }

  Future<void> _enviarCodigo() async {
    final tel = _normalizarTelefone(_telCtrl.text);
    if (tel.replaceAll(RegExp(r'\D'), '').length < 12) {
      _snack('Informe um telefone válido com DDD.', error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await _auth.requestCode(tel);
      if (!mounted) return;
      setState(() => _step = _Step.codigo);
      _snack('Código enviado por SMS.');
    } on ApiException catch (e) {
      _snack(e.message, error: true);
    } catch (_) {
      _snack('Não foi possível enviar o código. Tente novamente.', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _validarCodigo() async {
    final tel = _normalizarTelefone(_telCtrl.text);
    final codigo = _codigoCtrl.text.trim();
    if (codigo.length < 4) {
      _snack('Digite o código recebido.', error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await _auth.verifyCode(tel, codigo);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      _snack(e.message, error: true);
    } catch (_) {
      _snack('Código inválido ou expirado.', error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final naTelefone = _step == _Step.telefone;
    return Scaffold(
      appBar: AppBar(title: const Text('Entrar')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Text(
                naTelefone ? 'Entre com seu telefone' : 'Digite o código',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                naTelefone
                    ? 'Enviaremos um código por SMS para confirmar seu número.'
                    : 'Enviamos um SMS para ${_telCtrl.text}. O código expira em 5 minutos.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),
              if (naTelefone)
                TextField(
                  controller: _telCtrl,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+() -]'))],
                  decoration: const InputDecoration(
                    labelText: 'Telefone',
                    hintText: '(11) 99999-9999',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                )
              else
                TextField(
                  controller: _codigoCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Código',
                    hintText: '000000',
                    prefixIcon: Icon(Icons.sms_outlined),
                  ),
                ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: naTelefone ? 'Enviar código' : 'Confirmar',
                loading: _loading,
                onPressed: naTelefone ? _enviarCodigo : _validarCodigo,
              ),
              const SizedBox(height: 12),
              if (!naTelefone)
                TextButton(
                  onPressed: _loading ? null : () => setState(() => _step = _Step.telefone),
                  child: const Text('Trocar o número'),
                ),
              const Divider(height: 40),
              TextButton(
                onPressed: _loading
                    ? null
                    : () async {
                        final ok = await Navigator.of(context).push<bool>(
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                        if (ok == true && mounted) Navigator.of(context).pop(true);
                      },
                child: const Text('Entrar com e-mail e senha'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
