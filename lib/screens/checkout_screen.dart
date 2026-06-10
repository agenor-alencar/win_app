import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart.dart';
import '../models/address.dart';
import '../services/api_service.dart';

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
  double _freightValue = 15.00;

  List<Address> _savedAddresses = [];
  String? _selectedAddressId;
  bool _saveAddress = false;

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
      if (!mounted) return;
      setState(() => _savedAddresses = addresses);
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

  void _finishOrder() async {
    final cart = Provider.of<Cart>(context, listen: false);
    
    if (_cepController.text.isEmpty || _numeroController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha os campos obrigatórios.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Salva o endereço digitado na conta do usuário, se solicitado
      if (_saveAddress && _selectedAddressId == null && _userId != null) {
        await _apiService.createAddress(
          _userId!,
          Address(
            id: '',
            logradouro: _logradouroController.text,
            numero: _numeroController.text,
            complemento: _complementoController.text,
            bairro: _bairroController.text,
            cidade: _cidadeController.text,
            estado: _ufController.text,
            cep: _cepController.text,
          ),
        );
      }

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
        "formaPagamento": "PIX"
      };

      final orderResponse = await _apiService.createOrder(orderData);
      final pedidoId = orderResponse['id'];
      final pixResponse = await _apiService.generatePix(pedidoId);
      
      if (mounted) {
        _showPixDialog(pixResponse['qr_code_base64'], pixResponse['copy_paste']);
        cart.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally { setState(() => _isLoading = false); }
  }

  void _showPixDialog(String? qrCode, String? copyPaste) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Column(
          children: [
            Icon(Icons.pix, color: Color(0xFF32BCAD), size: 48),
            SizedBox(height: 8),
            Text('Pagamento PIX', style: TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Copie o código abaixo para pagar no seu banco:', textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
              child: SelectableText(
                copyPaste ?? 'Código Pix indisponível',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            child: const Text('VOLTAR PARA INÍCIO', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
              setState(() => _selectedAddressId = null);
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
            if (_selectedAddressId == null)
              CheckboxListTile(
                value: _saveAddress,
                onChanged: (v) => setState(() => _saveAddress = v ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text(
                  'Salvar este endereço na minha conta',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),

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
                  _buildRow('Frete', 'R\$ ${_freightValue.toStringAsFixed(2)}'),
                  const Divider(height: 32),
                  _buildRow('Total', 'R\$ ${(cart.totalAmount + _freightValue).toStringAsFixed(2)}', isTotal: true),
                ],
              ),
            ),
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity, height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _finishOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF007AFF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('FINALIZAR E PAGAR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
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
