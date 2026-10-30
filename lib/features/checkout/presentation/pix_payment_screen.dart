import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:win_app/core/network/api_service.dart';

/// Tela de pagamento PIX: exibe o QR Code (gerado no cliente a partir do
/// código EMV), o código copia-e-cola, uma contagem regressiva até a
/// expiração e confirma automaticamente quando o pagamento é aprovado.
class PixPaymentScreen extends StatefulWidget {
  /// Código EMV (copia e cola) retornado em billing.qrCode.
  final String pixCode;

  /// Valor total em reais.
  final double amount;

  /// ID da cobrança no Pagar.me (billing.billingId) — usado para consultar status.
  final String? billingId;

  /// Momento real de expiração do QR Code, vindo de billing.expiresAt do backend.
  /// Quando nulo, usa [fallbackWindow] (15 min, igual ao padrão do backend).
  final DateTime? expiresAt;

  /// Janela usada apenas quando o backend não informa expiresAt.
  final Duration fallbackWindow;

  const PixPaymentScreen({
    super.key,
    required this.pixCode,
    required this.amount,
    this.billingId,
    this.expiresAt,
    this.fallbackWindow = const Duration(minutes: 15),
  });

  @override
  State<PixPaymentScreen> createState() => _PixPaymentScreenState();
}

class _PixPaymentScreenState extends State<PixPaymentScreen> {
  static const _blue = Color(0xFF007AFF);
  static const _pixGreen = Color(0xFF32BCAD);

  final _apiService = ApiService();

  late int _secondsLeft;
  late int _totalSeconds; // baseline para a barra de progresso
  Timer? _countdownTimer;
  Timer? _statusTimer;
  bool _copied = false;
  bool _paid = false;

  @override
  void initState() {
    super.initState();
    // Tempo restante a partir do expiresAt real do backend (fallback: 15 min).
    final remaining = widget.expiresAt != null
        ? widget.expiresAt!.difference(DateTime.now()).inSeconds
        : widget.fallbackWindow.inSeconds;
    _secondsLeft = remaining > 0 ? remaining : 0;
    _totalSeconds = _secondsLeft > 0 ? _secondsLeft : widget.fallbackWindow.inSeconds;
    _startCountdown();
    _startStatusPolling();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _statusTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _startStatusPolling() {
    if (widget.billingId == null || widget.billingId!.isEmpty) return;
    // Verifica a cada 5s, como na aplicação web.
    _statusTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final status = await _apiService.checkPixStatus(widget.billingId!);
      if (!mounted) return;
      final s = status?.toLowerCase();
      if (s == 'paid' || s == 'aprovado' || s == 'approved') {
        _statusTimer?.cancel();
        _countdownTimer?.cancel();
        setState(() => _paid = true);
      }
    });
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: widget.pixCode));
    setState(() => _copied = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Código PIX copiado!'), duration: Duration(seconds: 2)),
    );
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  String get _formattedTime {
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  bool get _expired => _secondsLeft == 0;
  bool get _almostExpired => _secondsLeft > 0 && _secondsLeft < 300;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      appBar: AppBar(
        title: const Text('Pagamento PIX', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
        ),
      ),
      body: _paid ? _buildPaidState() : _buildPaymentState(),
    );
  }

  Widget _buildPaidState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 96),
            const SizedBox(height: 24),
            const Text('Pagamento confirmado!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text('Seu pedido foi pago com sucesso.',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('VOLTAR AO INÍCIO',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentState() {
    final progress = _totalSeconds == 0 ? 0.0 : _secondsLeft / _totalSeconds;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 8),
          const Icon(Icons.pix, color: _pixGreen, size: 40),
          const SizedBox(height: 8),
          const Text('Escaneie o QR Code para pagar',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('R\$ ${widget.amount.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontSize: 28, fontWeight: FontWeight.w900, color: _blue)),
          const SizedBox(height: 20),

          // QR Code
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _pixGreen, width: 3),
            ),
            child: _expired
                ? const SizedBox(
                    width: 220,
                    height: 220,
                    child: Center(
                      child: Text('QR Code expirado',
                          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                    ),
                  )
                : QrImageView(
                    data: widget.pixCode,
                    version: QrVersions.auto,
                    size: 220,
                    backgroundColor: Colors.white,
                  ),
          ),
          const SizedBox(height: 20),

          // Contagem regressiva + barra de progresso
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.timer_outlined,
                  size: 18, color: _almostExpired || _expired ? Colors.red : Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                _expired ? 'Expirado' : '$_formattedTime restantes',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: _almostExpired || _expired ? Colors.red : Colors.grey.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(
                  _almostExpired || _expired ? Colors.red : _pixGreen),
            ),
          ),
          const SizedBox(height: 24),

          // Código copia e cola
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SelectableText(
              widget.pixCode,
              style: const TextStyle(fontSize: 11, color: Colors.black87),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _expired ? null : _copyCode,
              icon: Icon(_copied ? Icons.check_rounded : Icons.copy_rounded, size: 18),
              label: Text(_copied ? 'Código copiado!' : 'Copiar código PIX',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _copied ? Colors.green : _blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Instruções
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F7FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Como pagar com PIX',
                    style: TextStyle(fontWeight: FontWeight.w800, color: _blue)),
                const SizedBox(height: 12),
                ..._buildSteps([
                  'Abra o aplicativo do seu banco',
                  'Escolha pagar com PIX',
                  'Escaneie o QR Code ou cole o código',
                  'Confirme e finalize o pagamento',
                ]),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.billingId != null && widget.billingId!.isNotEmpty) ...[
                const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey)),
                const SizedBox(width: 8),
                Text('Aguardando confirmação do pagamento...',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSteps(List<String> steps) {
    return List.generate(steps.length, (i) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: const BoxDecoration(color: _blue, shape: BoxShape.circle),
              child: Text('${i + 1}',
                  style: const TextStyle(
                      color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(steps[i], style: const TextStyle(fontSize: 13)),
              ),
            ),
          ],
        ),
      );
    });
  }
}
