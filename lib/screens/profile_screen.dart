import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  String _nome = '';
  String _email = '';
  String _cpf = '';
  String _telefone = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nome = prefs.getString('user_nome') ?? 'Usuário WIN';
      _email = prefs.getString('user_email') ?? '';
      _cpf = prefs.getString('user_cpf') ?? '';
      _telefone = prefs.getString('user_telefone') ?? '';
    });
  }

  void _handleLogout() async {
    await _authService.logout();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        title: const Text('Meu Perfil', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF007AFF), width: 2),
                        ),
                        child: const CircleAvatar(
                          radius: 50,
                          backgroundColor: Color(0xFFF1F3F5),
                          child: Icon(Icons.person_rounded, size: 60, color: Color(0xFF007AFF)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(_nome, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                  Text(_email, style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                ],
              ),
            ),
            const SizedBox(height: 40),

            _buildSectionTitle('Informações Pessoais'),
            _buildInfoCard([
              _buildInfoRow(Icons.badge_outlined, 'CPF', _cpf),
              _buildInfoRow(Icons.phone_android_rounded, 'Telefone', _telefone),
            ]),

            const SizedBox(height: 24),
            _buildSectionTitle('Minha Atividade'),
            _buildInfoCard([
              // AGORA NAVEGA PARA MEUS PEDIDOS
              _buildMenuRow(Icons.shopping_bag_outlined, 'Meus Pedidos', () {
                Navigator.pushNamed(context, '/orders');
              }),
              _buildMenuRow(Icons.favorite_border_rounded, 'Favoritos', () {
                Navigator.pushNamed(context, '/favorites');
              }),
              _buildMenuRow(Icons.location_on_outlined, 'Meus Endereços', () {}),
            ]),

            const SizedBox(height: 24),
            _buildSectionTitle('Conta'),
            _buildInfoCard([
              _buildMenuRow(Icons.logout_rounded, 'Sair da Conta', _handleLogout, color: Colors.redAccent),
            ]),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87)),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF007AFF), size: 22),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600)),
              Text(value.isNotEmpty ? value : 'Não informado', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuRow(IconData icon, String title, VoidCallback onTap, {Color color = Colors.black87}) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color, size: 22),
      title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
