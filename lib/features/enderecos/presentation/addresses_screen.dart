import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:win_app/features/enderecos/domain/address.dart';
import 'package:win_app/core/network/api_service.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  final ApiService _apiService = ApiService();

  String? _userId;
  bool _isLoading = true;
  List<Address> _addresses = [];

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('user_id');
    if (_userId == null || _userId!.isEmpty) {
      setState(() {
        _addresses = [];
        _isLoading = false;
      });
      return;
    }
    final addresses = await _apiService.getAddressesByUser(_userId!);
    if (!mounted) return;
    setState(() {
      _addresses = addresses;
      _isLoading = false;
    });
  }

  Future<void> _confirmDelete(Address address) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Excluir endereço?',
            style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text(address.descricaoCompleta),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('EXCLUIR',
                style: TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final ok = await _apiService.deleteAddress(address.id);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Endereço excluído.')),
      );
      _loadAddresses();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível excluir o endereço.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _setMain(Address address) async {
    final ok = await _apiService.setMainAddress(address.id);
    if (!mounted) return;
    if (ok) {
      _loadAddresses();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível definir como principal.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _openAddressForm() async {
    if (_userId == null || _userId!.isEmpty) return;
    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => _AddressForm(userId: _userId!),
    );
    if (created == true) _loadAddresses();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        title: const Text('Meus Endereços',
            style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddressForm,
        backgroundColor: const Color(0xFF007AFF),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Novo endereço',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAddresses,
              child: _addresses.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: _addresses.length,
                      itemBuilder: (context, index) =>
                          _buildAddressCard(_addresses[index]),
                    ),
            ),
    );
  }

  Widget _buildEmptyState() {
    // ListView para o RefreshIndicator funcionar mesmo sem itens
    return ListView(
      children: [
        const SizedBox(height: 120),
        Icon(Icons.location_off_outlined, size: 80, color: Colors.grey.shade300),
        const SizedBox(height: 20),
        const Center(
          child: Text(
            'Nenhum endereço cadastrado',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Toque em "Novo endereço" para adicionar.',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildAddressCard(Address address) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: address.principal
              ? const Color(0xFF007AFF)
              : Colors.grey.shade100,
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Icon(
            address.principal
                ? Icons.location_on_rounded
                : Icons.location_on_outlined,
            color: const Color(0xFF007AFF),
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (address.principal)
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF007AFF).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'PRINCIPAL',
                      style: TextStyle(
                          color: Color(0xFF007AFF),
                          fontSize: 10,
                          fontWeight: FontWeight.w900),
                    ),
                  ),
                Text(
                  '${address.logradouro}, ${address.numero}'
                  '${address.complemento.isNotEmpty ? ' — ${address.complemento}' : ''}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  '${address.bairro} — ${address.cidade}/${address.estado}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                Text(
                  'CEP ${address.cep}',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            children: [
              if (!address.principal)
                IconButton(
                  tooltip: 'Definir como principal',
                  icon: const Icon(Icons.star_border_rounded,
                      color: Colors.amber),
                  onPressed: () => _setMain(address),
                ),
              IconButton(
                tooltip: 'Excluir',
                icon: const Icon(Icons.delete_outline_rounded,
                    color: Colors.redAccent),
                onPressed: () => _confirmDelete(address),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Formulário de cadastro de endereço (bottom sheet).
class _AddressForm extends StatefulWidget {
  final String userId;
  const _AddressForm({required this.userId});

  @override
  State<_AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<_AddressForm> {
  final _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  final _cepController = TextEditingController();
  final _logradouroController = TextEditingController();
  final _numeroController = TextEditingController();
  final _complementoController = TextEditingController();
  final _bairroController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _ufController = TextEditingController();

  bool _principal = false;
  bool _isSaving = false;
  bool _isSearchingCep = false;

  @override
  void dispose() {
    _cepController.dispose();
    _logradouroController.dispose();
    _numeroController.dispose();
    _complementoController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
    _ufController.dispose();
    super.dispose();
  }

  Future<void> _searchCep(String cep) async {
    final cleaned = cep.replaceAll(RegExp(r'\D'), '');
    if (cleaned.length != 8) return;
    setState(() => _isSearchingCep = true);
    final data = await _apiService.getAddressByCep(cleaned);
    if (!mounted) return;
    if (data != null) {
      _logradouroController.text = data['logradouro'] ?? '';
      _bairroController.text = data['bairro'] ?? '';
      _cidadeController.text = data['localidade'] ?? data['cidade'] ?? '';
      _ufController.text = data['uf'] ?? data['estado'] ?? '';
    }
    setState(() => _isSearchingCep = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final address = Address(
      id: '',
      logradouro: _logradouroController.text.trim(),
      numero: _numeroController.text.trim(),
      complemento: _complementoController.text.trim(),
      bairro: _bairroController.text.trim(),
      cidade: _cidadeController.text.trim(),
      estado: _ufController.text.trim().toUpperCase(),
      cep: _cepController.text.replaceAll(RegExp(r'\D'), ''),
      principal: _principal,
    );

    try {
      await _apiService.createAddress(widget.userId, address);
      if (!mounted) return;
      setState(() => _isSaving = false);
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar o endereço: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Novo Endereço',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 20),
              _buildField(
                _cepController,
                'CEP',
                keyboardType: TextInputType.number,
                onChanged: _searchCep,
                validator: (v) =>
                    (v == null || v.replaceAll(RegExp(r'\D'), '').length != 8)
                        ? 'CEP inválido'
                        : null,
                suffix: _isSearchingCep
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : null,
              ),
              const SizedBox(height: 12),
              _buildField(_logradouroController, 'Rua / Logradouro',
                  validator: _required),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildField(_numeroController, 'Nº',
                        keyboardType: TextInputType.number,
                        validator: _required),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: _buildField(_complementoController, 'Complemento'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildField(_bairroController, 'Bairro', validator: _required),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: _buildField(_cidadeController, 'Cidade',
                        validator: _required),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: _buildField(_ufController, 'UF',
                        validator: _required),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: _principal,
                onChanged: (v) => setState(() => _principal = v ?? false),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text('Definir como endereço principal',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('SALVAR ENDEREÇO',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Obrigatório' : null;

  Widget _buildField(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
    Function(String)? onChanged,
    String? Function(String?)? validator,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFFBFBFB),
        suffixIcon: suffix,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
      ),
    );
  }
}
