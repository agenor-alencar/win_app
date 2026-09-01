import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart.dart';
import '../models/address.dart';
import '../models/coupon.dart';
import '../services/api_service.dart';
import 'pix_payment_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _apiService = ApiService();
  
  final _cepController = TextEditingController();
  final _logradouroController = TextEditingController();
  final _numeroController = TextEditingController();
  final _bairroController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _ufController = TextEditingController();
  final _complementoController = TextEditingController();

  final _nomeController = TextEditingController();
  final _emailController = TextEditingController();
  final _cpfController = TextEditingController();
  final _telefoneController = TextEditingController();

  String? _userId;
  bool _isLoading = false;

  List<Address> _savedAddresses = [];
  String? _selectedAddressId;

  // ─── Frete dinâmico (Uber Direct via backend) ──────────────────────────────
  // _freteValor nulo = ainda não calculado; nunca "chutamos" um valor.
  double? _freteValor;
  String? _freteErro;
  bool _loadingFrete = false;
  bool _freteGratisPrimeiraCompra = false;

  // ─── Cupom ─────────────────────────────────────────────────────────────────
  final _cupomController = TextEditingController();
  List<Coupon> _myCoupons = [];
  Coupon? _appliedCoupon;
  String? _couponError;
  bool _applyingCoupon = false;

  /// Frete grátis por benefício (1ª compra ou cupom de frete grátis) — só preview.
  bool get _freteGratis =>
      _freteGratisPrimeiraCompra || (_appliedCoupon?.isFreteGratis ?? false);

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('user_id');
      _nomeController.text = prefs.getString('user_nome') ?? '';
      _emailController.text = prefs.getString('user_email') ?? '';
      _cpfController.text = prefs.getString('user_cpf') ?? '';
      _telefoneController.text = prefs.getString('user_telefone') ?? '';
    });
    if (_userId != null && _userId!.isNotEmpty) {
      final addresses = await _apiService.getAddressesByUser(_userId!);
      final freteGratis =
          await _apiService.isFreteGratisPrimeiraCompra(_userId!);
      final cupons = await _apiService.getMyCoupons();
      if (!mounted) return;
      setState(() {
        _savedAddresses = addresses;
        _freteGratisPrimeiraCompra = freteGratis;
        _myCoupons = cupons;
      });
      // Pré-seleciona o endereço principal, se houver
      for (final addr in addresses) {
        if (addr.principal) {
          _applyAddress(addr);
          break;
        }
      }
    }
  }

  void _applyAddress(Address addr) {
    setState(() {
      _selectedAddressId = addr.id;
      _cepController.text = addr.cep;
      _logradouroController.text = addr.logradouro;
      _numeroController.text = addr.numero;
      _complementoController.text = addr.complemento;
      _bairroController.text = addr.bairro;
      _cidadeController.text = addr.cidade;
      _ufController.text = addr.estado;
    });
    _calcularFrete();
  }

  /// Peso estimado: 0,5 kg por item, mínimo 1 kg (mesma regra da web).
  double _pesoTotalKg(Cart cart) {
    final peso = cart.items.values
        .fold<double>(0, (t, item) => t + item.quantity * 0.5);
    return peso < 1 ? 1 : peso;
  }

  /// Calcula o frete real para o endereço selecionado.
  /// Exige endereço salvo (UUID) e produto com lojista identificado.
  Future<void> _calcularFrete() async {
    final cart = Provider.of<Cart>(context, listen: false);

    if (_freteGratisPrimeiraCompra) {
      setState(() {
        _freteValor = 0;
        _freteErro = null;
      });
      return;
    }

    if (_selectedAddressId == null || cart.items.isEmpty) return;

    final lojistaId = cart.items.values.first.product.lojistaId;
    if (lojistaId == null || lojistaId.isEmpty) {
      setState(() {
        _freteValor = null;
        _freteErro = 'Produto sem loja identificada — não foi possível calcular o frete.';
      });
      return;
    }

    setState(() {
      _loadingFrete = true;
      _freteErro = null;
    });

    final resultado = await _apiService.calcularFrete(
      lojistaId: lojistaId,
      enderecoEntregaId: _selectedAddressId!,
      pesoTotalKg: _pesoTotalKg(cart),
    );

    if (!mounted) return;
    setState(() {
      _loadingFrete = false;
      if (resultado['sucesso'] == true && resultado['valorFreteTotal'] != null) {
        _freteValor = (resultado['valorFreteTotal'] as num).toDouble();
        _freteErro = null;
      } else {
        _freteValor = null;
        _freteErro = resultado['erro']?.toString() ??
            'Não foi possível calcular o frete para este endereço.';
      }
    });
  }

  /// Salva o endereço digitado, seleciona-o e calcula o frete.
  /// (O cálculo de frete do backend exige um endereço salvo com UUID.)
  Future<void> _salvarEnderecoECalcular() async {
    if (_userId == null) return;
    if (_cepController.text.isEmpty ||
        _numeroController.text.isEmpty ||
        _logradouroController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha o endereço para calcular o frete.')),
      );
      return;
    }

    setState(() => _loadingFrete = true);
    try {
      // O backend valida: cep com exatamente 8 dígitos e estado em UF maiúscula.
      final created = await _apiService.createAddress(
        _userId!,
        Address(
          id: '',
          logradouro: _logradouroController.text.trim(),
          numero: _numeroController.text.trim(),
          complemento: _complementoController.text.trim(),
          bairro: _bairroController.text.trim(),
          cidade: _cidadeController.text.trim(),
          estado: _ufController.text.trim().toUpperCase(),
          cep: _cepController.text.replaceAll(RegExp(r'\D'), ''),
        ),
      );
      if (!mounted) return;
      setState(() {
        _savedAddresses = [..._savedAddresses, created];
        _selectedAddressId = created.id;
      });
      await _calcularFrete();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingFrete = false;
        _freteErro = 'Erro ao salvar endereço: $e';
      });
    }
  }

  void _searchCep(String cep) async {
    if (cep.length != 8) return;
    setState(() => _isLoading = true);
    try {
      final address = await _apiService.getAddressByCep(cep);
      if (address != null) {
        setState(() {
          _logradouroController.text = address['logradouro'] ?? '';
          _bairroController.text = address['bairro'] ?? '';
          _cidadeController.text = address['localidade'] ?? '';
          _ufController.text = address['uf'] ?? '';
        });
      }
    } catch (e) {} 
    finally { setState(() => _isLoading = false); }
  }

  /// Valida e aplica um cupom pelo código. O backend confirma a aplicação
  /// (frete grátis) na criação do pedido; aqui só validamos e mostramos o preview.
  Future<void> _aplicarCupom(String codigo) async {
    final code = codigo.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() {
      _applyingCoupon = true;
      _couponError = null;
    });
    try {
      final cupom = await _apiService.validateCouponTyped(code);
      final cart = Provider.of<Cart>(context, listen: false);
      if (cupom.valorMinimoPedido > 0 && cart.totalAmount < cupom.valorMinimoPedido) {
        setState(() {
          _applyingCoupon = false;
          _couponError =
              'Este cupom exige um pedido mínimo de R\$ ${cupom.valorMinimoPedido.toStringAsFixed(2)}.';
        });
        return;
      }
      setState(() {
        _appliedCoupon = cupom;
        _cupomController.text = cupom.codigo;
        _applyingCoupon = false;
      });
    } catch (_) {
      setState(() {
        _applyingCoupon = false;
        _couponError = 'Cupom inválido ou expirado.';
      });
    }
  }

  void _removerCupom() {
    setState(() {
      _appliedCoupon = null;
      _couponError = null;
      _cupomController.clear();
    });
  }

  void _finishOrder() async {
    final cart = Provider.of<Cart>(context, listen: false);

    if (_cepController.text.isEmpty || _numeroController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha os campos obrigatórios.')),
      );
      return;
    }

    // Nunca finalizamos um pedido com frete indefinido ou com erro de cotação,
    // exceto quando há frete grátis garantido (1ª compra ou cupom).
    if (_freteErro != null && !_freteGratis) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_freteErro!), backgroundColor: Colors.red),
      );
      return;
    }
    if (!_freteGratis && _freteValor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Calcule o frete para este endereço antes de finalizar.')),
      );
      return;
    }

    // Com frete grátis, enviamos 0; senão o valor cotado. Se houver cupom, o
    // backend revalida e aplica o benefício (rollback se o cupom for inválido).
    final double frete = _freteGratis ? 0 : _freteValor!;

    setState(() => _isLoading = true);

    try {
      // JSON AJUSTADO CONFORME O ERRO 400 DO SEU SPRING BOOT
      final orderData = {
        "usuarioId": _userId, // Adicionado aqui
        "itens": cart.items.values.map((item) => {
          "produtoId": item.product.id,
          "quantidade": item.quantity,
          "precoUnitario": item.product.preco // Adicionado aqui
        }).toList(),
        "enderecoEntrega": { // Mudado de 'endereco' para 'enderecoEntrega'
          "cep": _cepController.text,
          "logradouro": _logradouroController.text,
          "numero": _numeroController.text,
          "bairro": _bairroController.text,
          "cidade": _cidadeController.text,
          "uf": _ufController.text,
          "complemento": _complementoController.text,
        },
        "frete": double.parse(frete.toStringAsFixed(2)),
        // Só o código vai no pedido; o backend valida e aplica (ex.: zera o frete).
        if (_appliedCoupon != null) "cupomCodigo": _appliedCoupon!.codigo,
        "formaPagamento": "PIX"
      };

      final orderResponse = await _apiService.createOrder(orderData);
      final pedidoId = orderResponse['id'];
      final pixResponse = await _apiService.generatePix(
        pedidoId,
        nome: _nomeController.text,
        email: _emailController.text,
        cpf: _cpfController.text,
        telefone: _telefoneController.text,
      );

      // O backend devolve o QR Code aninhado em "billing" (billing.qrCode = copia e cola).
      final billing = pixResponse['billing'] as Map<String, dynamic>?;
      final copiaECola = billing?['qrCode']?.toString();
      // amount vem em centavos; cai para o total local se ausente.
      final amountCentavos = billing?['amount'];
      final valorPago = amountCentavos is num
          ? amountCentavos / 100.0
          : cart.totalAmount + frete;
      final billingId = billing?['billingId']?.toString();
      // expiresAt vem como timestamp ISO do Pagar.me; a tela calcula o tempo restante.
      final expiresAt = DateTime.tryParse(billing?['expiresAt']?.toString() ?? '');

      if (copiaECola == null || copiaECola.isEmpty) {
        // Surface o motivo real do servidor (ex.: CPF inválido, Pagar.me recusou)
        // em vez de uma mensagem genérica, para facilitar o diagnóstico.
        final motivo = pixResponse['message'] ??
            pixResponse['error'] ??
            billing?['message'] ??
            billing?['status'] ??
            pixResponse.toString();
        throw Exception('PIX não gerado: $motivo');
      }

      if (mounted) {
        cart.clear();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PixPaymentScreen(
              pixCode: copiaECola,
              amount: valorPago,
              billingId: billingId,
              expiresAt: expiresAt,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally { setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<Cart>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        title: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white, elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Seus Dados', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            _buildTextField(_nomeController, 'Nome Completo'),
            const SizedBox(height: 12),
            _buildTextField(_emailController, 'E-mail', keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildTextField(_cpfController, 'CPF', keyboardType: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(child: _buildTextField(_telefoneController, 'Telefone', keyboardType: TextInputType.phone)),
              ],
            ),
            
            const SizedBox(height: 32),
            const Text('Endereço de Entrega', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            if (_savedAddresses.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _savedAddresses.map((addr) {
                  final selected = addr.id == _selectedAddressId;
                  return ChoiceChip(
                    selected: selected,
                    onSelected: (_) => _applyAddress(addr),
                    selectedColor: const Color(0xFF007AFF).withOpacity(0.12),
                    avatar: Icon(
                      addr.principal ? Icons.star_rounded : Icons.location_on_outlined,
                      size: 16,
                      color: const Color(0xFF007AFF),
                    ),
                    label: Text(
                      '${addr.logradouro}, ${addr.numero}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                        color: selected ? const Color(0xFF007AFF) : Colors.black87,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
            _buildTextField(_cepController, 'CEP', keyboardType: TextInputType.number, onChanged: (v) {
              // Endereço alterado manualmente: frete precisa ser recalculado.
              setState(() {
                _selectedAddressId = null;
                _freteValor = null;
                _freteErro = null;
              });
              _searchCep(v);
            }),
            const SizedBox(height: 12),
            _buildTextField(_logradouroController, 'Rua / Logradouro'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(flex: 2, child: _buildTextField(_numeroController, 'Nº')),
                const SizedBox(width: 12),
                Expanded(flex: 3, child: _buildTextField(_complementoController, 'Complemento')),
              ],
            ),
            const SizedBox(height: 12),
            _buildTextField(_bairroController, 'Bairro'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(flex: 4, child: _buildTextField(_cidadeController, 'Cidade')),
                const SizedBox(width: 12),
                Expanded(flex: 1, child: _buildTextField(_ufController, 'UF')),
              ],
            ),
            // Endereço digitado (não salvo): para calcular o frete o backend
            // exige um endereço salvo, então salvamos e calculamos num passo só.
            if (_selectedAddressId == null && !_freteGratis) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _loadingFrete ? null : _salvarEnderecoECalcular,
                  icon: const Icon(Icons.local_shipping_outlined, size: 18),
                  label: const Text('Salvar endereço e calcular frete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF007AFF),
                    side: const BorderSide(color: Color(0xFF007AFF)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 32),
            const Text('Cupom', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 12),
            _buildCouponSection(),

            const SizedBox(height: 32),
            const Text('Resumo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: _buildBoxDecoration(),
              child: Column(
                children: [
                  _buildRow('Subtotal', 'R\$ ${cart.totalAmount.toStringAsFixed(2)}'),
                  const SizedBox(height: 12),
                  _buildFreteRow(),
                  if (_freteErro != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 16),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(_freteErro!,
                              style: const TextStyle(color: Colors.red, fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                  if (_appliedCoupon != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.local_offer_rounded, size: 14, color: Colors.green),
                            const SizedBox(width: 6),
                            Text('Cupom ${_appliedCoupon!.codigo}',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                          ],
                        ),
                        Text(_appliedCoupon!.beneficio,
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700, color: Colors.green)),
                      ],
                    ),
                  ],
                  const Divider(height: 32),
                  _buildRow(
                    'Total',
                    (!_freteGratis && _freteValor == null)
                        ? 'R\$ ${cart.totalAmount.toStringAsFixed(2)} + frete'
                        : 'R\$ ${(cart.totalAmount + (_freteGratis ? 0 : _freteValor!)).toStringAsFixed(2)}',
                    isTotal: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity, height: 56,
              child: Builder(builder: (context) {
                final freteIndisponivel = !_freteGratis && _freteValor == null;
                final desabilitado = _isLoading || _loadingFrete || freteIndisponivel;
                return ElevatedButton(
                  onPressed: desabilitado ? null : _finishOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          freteIndisponivel ? 'CALCULE O FRETE' : 'FINALIZAR E PAGAR',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {TextInputType? keyboardType, Function(String)? onChanged}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label, filled: true, fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
      ),
    );
  }

  /// Linha de frete que reflete o estado: calculando / grátis / valor / pendente.
  Widget _buildFreteRow() {
    String valor;
    Color cor = Colors.black;
    // Quando o frete original está cotado mas há benefício (cupom/1ª compra),
    // mostramos o valor riscado + "Grátis".
    final bool freteRiscado =
        _freteGratis && !_freteGratisPrimeiraCompra && _freteValor != null;
    if (_loadingFrete) {
      valor = 'Calculando...';
      cor = Colors.grey;
    } else if (_freteGratis) {
      valor = 'Grátis 🎉';
      cor = Colors.green;
    } else if (_freteValor != null) {
      valor = 'R\$ ${_freteValor!.toStringAsFixed(2)}';
    } else {
      valor = 'Selecione o endereço';
      cor = Colors.grey;
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Frete', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        Row(
          children: [
            if (freteRiscado) ...[
              Text('R\$ ${_freteValor!.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      decoration: TextDecoration.lineThrough)),
              const SizedBox(width: 6),
            ],
            Text(valor,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: cor)),
          ],
        ),
      ],
    );
  }

  /// Seção de cupom: campo + aplicar, chips dos "meus cupons" e estado aplicado.
  Widget _buildCouponSection() {
    if (_appliedCoupon != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.green.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cupom ${_appliedCoupon!.codigo} aplicado',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                  Text(_appliedCoupon!.beneficio,
                      style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            TextButton(
              onPressed: _removerCupom,
              child: const Text('Remover', style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildTextField(_cupomController, 'Código do cupom'),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _applyingCoupon ? null : () => _aplicarCupom(_cupomController.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007AFF),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _applyingCoupon
                    ? const SizedBox(
                        width: 18, height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Aplicar', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        if (_couponError != null) ...[
          const SizedBox(height: 8),
          Text(_couponError!, style: const TextStyle(color: Colors.red, fontSize: 12)),
        ],
        if (_myCoupons.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Seus cupons',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _myCoupons.map((c) {
              return ActionChip(
                avatar: const Icon(Icons.local_offer_outlined, size: 16, color: Color(0xFF007AFF)),
                label: Text('${c.codigo} · ${c.beneficio}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                onPressed: () => _aplicarCupom(c.codigo),
                backgroundColor: const Color(0xFF007AFF).withOpacity(0.06),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: const Color(0xFF007AFF).withOpacity(0.2)),
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: isTotal ? 18 : 14, fontWeight: isTotal ? FontWeight.w900 : FontWeight.w500)),
        Text(value, style: TextStyle(fontSize: isTotal ? 20 : 14, fontWeight: isTotal ? FontWeight.w900 : FontWeight.w700, color: isTotal ? const Color(0xFF007AFF) : Colors.black)),
      ],
    );
  }

  BoxDecoration _buildBoxDecoration() {
    return BoxDecoration(
      color: Colors.white, borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.grey.shade100),
    );
  }
}
