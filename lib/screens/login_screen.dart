import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  // Controllers — login
  final _loginEmailCtrl = TextEditingController();
  final _loginPasswordCtrl = TextEditingController();

  // Controllers — cadastro
  final _regNomeCtrl = TextEditingController();
  final _regEmailCtrl = TextEditingController();
  final _regCpfCtrl = TextEditingController();
  final _regTelCtrl = TextEditingController();
  final _regPasswordCtrl = TextEditingController();
  final _regConfirmPasswordCtrl = TextEditingController();

  final _authService = AuthService();
  late TabController _tabController;

  bool _isLoading = false;
  bool _obscureLogin = true;
  bool _obscureReg = true;
  bool _obscureRegConfirm = true;

  // Erros de validação inline
  String? _regNomeError;
  String? _regEmailError;
  String? _regCpfError;
  String? _regTelError;
  String? _regPasswordError;
  String? _regConfirmPasswordError;

  static const _blue = Color(0xFF007AFF);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailCtrl.dispose();
    _loginPasswordCtrl.dispose();
    _regNomeCtrl.dispose();
    _regEmailCtrl.dispose();
    _regCpfCtrl.dispose();
    _regTelCtrl.dispose();
    _regPasswordCtrl.dispose();
    _regConfirmPasswordCtrl.dispose();
    super.dispose();
  }

  // ───────── LOGIN ─────────
  Future<void> _handleLogin() async {
    if (_loginEmailCtrl.text.isEmpty || _loginPasswordCtrl.text.isEmpty) {
      _showSnack('Preencha todos os campos');
      return;
    }
    setState(() => _isLoading = true);
    final success = await _authService.login(
      _loginEmailCtrl.text.trim(),
      _loginPasswordCtrl.text.trim(),
    );
    setState(() => _isLoading = false);

    if (!mounted) return;
    if (success) {
      _onAuthSuccess();
    } else {
      _showSnack('E-mail ou senha incorretos.', error: true);
    }
  }

  /// Volta para a tela anterior (guard) ou para o menu principal.
  void _onAuthSuccess() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop(true); // retorna ao ponto onde o usuário estava
    } else {
      navigator.pushReplacementNamed('/home');
    }
  }

  // ───────── CADASTRO ─────────
  bool _validateRegister() {
    bool ok = true;
    setState(() {
      _regNomeError = _regNomeCtrl.text.trim().length < 3
          ? 'Nome deve ter ao menos 3 caracteres'
          : null;
      _regEmailError = !_regEmailCtrl.text.contains('@')
          ? 'E-mail inválido'
          : null;
      final cpf = _regCpfCtrl.text.replaceAll(RegExp(r'\D'), '');
      _regCpfError = cpf.length != 11 ? 'CPF deve ter 11 dígitos' : null;
      final tel = _regTelCtrl.text.replaceAll(RegExp(r'\D'), '');
      _regTelError =
          tel.length < 10 ? 'Telefone deve ter ao menos 10 dígitos' : null;
      _regPasswordError = _regPasswordCtrl.text.length < 6
          ? 'Senha deve ter ao menos 6 caracteres'
          : null;
      _regConfirmPasswordError =
          _regPasswordCtrl.text != _regConfirmPasswordCtrl.text
              ? 'As senhas não conferem'
              : null;
    });

    ok = _regNomeError == null &&
        _regEmailError == null &&
        _regCpfError == null &&
        _regTelError == null &&
        _regPasswordError == null &&
        _regConfirmPasswordError == null;
    return ok;
  }

  Future<void> _handleRegister() async {
    if (!_validateRegister()) return;

    setState(() => _isLoading = true);
    final error = await _authService.register(
      nome: _regNomeCtrl.text.trim(),
      email: _regEmailCtrl.text.trim(),
      password: _regPasswordCtrl.text.trim(),
      cpf: _regCpfCtrl.text.replaceAll(RegExp(r'\D'), ''),
      telefone: _regTelCtrl.text.replaceAll(RegExp(r'\D'), ''),
    );
    setState(() => _isLoading = false);

    if (!mounted) return;
    if (error == null) {
      _onAuthSuccess();
    } else {
      _showSnack(error, error: true);
    }
  }

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.redAccent : Colors.black87,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(12),
    ));
  }

  // ───────── BUILD ─────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              // Botão de fechar quando a tela abre por cima da navegação
              if (Navigator.of(context).canPop())
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.black54),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                  ),
                )
              else
                const SizedBox(height: 40),
              // Logo
              const Text(
                'WIN',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: _blue,
                  letterSpacing: -2,
                ),
              ),
              const Text(
                'Marketplace Local',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 32),

              // Card principal
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      _tabController.index == 0 ? 'Bem-vindo' : 'Criar Conta',
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _tabController.index == 0
                          ? 'Entre na sua conta'
                          : 'Preencha seus dados para continuar',
                      style:
                          const TextStyle(color: Colors.grey, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    // Seletor de abas
                    _buildTabSelector(),
                    const SizedBox(height: 24),

                    // Conteúdo animado
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 280),
                      switchInCurve: Curves.easeInOut,
                      switchOutCurve: Curves.easeInOut,
                      transitionBuilder: (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                      child: _tabController.index == 0
                          ? _buildLoginForm()
                          : _buildRegisterForm(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const Text(
                'Ao continuar, você concorda com nossos Termos de Uso e\nPolítica de Privacidade',
                style: TextStyle(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F3F5),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildTab(0, 'Entrar'),
          _buildTab(1, 'Criar Conta'),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String label) {
    final selected = _tabController.index == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          _tabController.animateTo(index);
          setState(() {});
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight:
                  selected ? FontWeight.bold : FontWeight.w500,
              color: selected ? Colors.black87 : Colors.grey,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  // ───────── FORMULÁRIO DE LOGIN ─────────
  Widget _buildLoginForm() {
    return Column(
      key: const ValueKey('login'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('E-mail'),
        _inputField(
          controller: _loginEmailCtrl,
          hint: 'seu@email.com',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _label('Senha'),
        _inputField(
          controller: _loginPasswordCtrl,
          hint: 'Sua senha',
          obscure: _obscureLogin,
          suffixIcon: _eyeIcon(
            _obscureLogin,
            () => setState(() => _obscureLogin = !_obscureLogin),
          ),
        ),
        const SizedBox(height: 24),
        _submitButton('Entrar', _handleLogin),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () {},
            child: const Text(
              'Esqueci minha senha',
              style: TextStyle(color: _blue, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  // ───────── FORMULÁRIO DE CADASTRO ─────────
  Widget _buildRegisterForm() {
    return Column(
      key: const ValueKey('register'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('Nome completo'),
        _inputField(
          controller: _regNomeCtrl,
          hint: 'João Silva',
          errorText: _regNomeError,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: 14),
        _label('E-mail'),
        _inputField(
          controller: _regEmailCtrl,
          hint: 'seu@email.com',
          keyboardType: TextInputType.emailAddress,
          errorText: _regEmailError,
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('CPF'),
                  _inputField(
                    controller: _regCpfCtrl,
                    hint: '000.000.000-00',
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      _CpfFormatter(),
                    ],
                    errorText: _regCpfError,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Telefone'),
                  _inputField(
                    controller: _regTelCtrl,
                    hint: '(00) 00000-0000',
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      _PhoneFormatter(),
                    ],
                    errorText: _regTelError,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        _label('Senha'),
        _inputField(
          controller: _regPasswordCtrl,
          hint: 'Mínimo 6 caracteres',
          obscure: _obscureReg,
          errorText: _regPasswordError,
          suffixIcon: _eyeIcon(
            _obscureReg,
            () => setState(() => _obscureReg = !_obscureReg),
          ),
        ),
        const SizedBox(height: 14),
        _label('Confirmar senha'),
        _inputField(
          controller: _regConfirmPasswordCtrl,
          hint: 'Repita a senha',
          obscure: _obscureRegConfirm,
          errorText: _regConfirmPasswordError,
          suffixIcon: _eyeIcon(
            _obscureRegConfirm,
            () => setState(
                () => _obscureRegConfirm = !_obscureRegConfirm),
          ),
        ),
        const SizedBox(height: 24),
        _submitButton('Criar Conta', _handleRegister),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: () {
              _tabController.animateTo(0);
              setState(() {});
            },
            child: const Text(
              'Já tenho uma conta  →  Entrar',
              style: TextStyle(color: _blue, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  // ───────── WIDGETS REUTILIZÁVEIS ─────────
  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13)),
      );

  Widget _inputField({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? errorText,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        errorText: errorText,
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _blue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
    );
  }

  Widget _submitButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _blue,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : Text(label,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _eyeIcon(bool obscure, VoidCallback onTap) => IconButton(
        icon: Icon(
          obscure
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          size: 20,
          color: Colors.grey,
        ),
        onPressed: onTap,
      );
}

// ───────── FORMATADORES ─────────
class _CpfFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue next) {
    final digits = next.text.replaceAll(RegExp(r'\D'), '');
    final buf = StringBuffer();
    for (int i = 0; i < digits.length && i < 11; i++) {
      if (i == 3 || i == 6) buf.write('.');
      if (i == 9) buf.write('-');
      buf.write(digits[i]);
    }
    final str = buf.toString();
    return TextEditingValue(
      text: str,
      selection: TextSelection.collapsed(offset: str.length),
    );
  }
}

class _PhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue old, TextEditingValue next) {
    final digits = next.text.replaceAll(RegExp(r'\D'), '');
    final buf = StringBuffer();
    for (int i = 0; i < digits.length && i < 11; i++) {
      if (i == 0) buf.write('(');
      if (i == 2) buf.write(') ');
      if (i == 7) buf.write('-');
      buf.write(digits[i]);
    }
    final str = buf.toString();
    return TextEditingValue(
      text: str,
      selection: TextSelection.collapsed(offset: str.length),
    );
  }
}
