import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/shared_widgets.dart';

class PaymentMethodScreen extends StatefulWidget {
  const PaymentMethodScreen({super.key});
  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  String _selected = 'fpx';

  final _methods = [
    ('fpx', 'FPX', 'Online Banking (FPX)', 'Maybank, CIMB, RHB, HLB + more',
        Color(0xFF003B8E), Color(0xFFE6F1FB)),
    ('card', 'CARD', 'Credit / Debit Card', 'Visa, Mastercard, AmEx',
        Color(0xFF1A1F71), Color(0xFFF0F0FF)),
    ('tng', 'TNG', "Touch 'n Go eWallet", 'Instant transfer',
        Color(0xFF72243E), Color(0xFFFBEAF0)),
    ('grab', 'GBY', 'GrabPay', 'Grab wallet balance',
        Color(0xFF27500A), Color(0xFFEAF3DE)),
    ('bank', 'DB', 'Direct Bank Transfer', 'Manual, 1–2 working days',
        Color(0xFF444441), Color(0xFFF1EFE8)),
  ];

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    final total = (args['totalPrice'] as double?) ?? 11600.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          BookingProgressBar(currentStep: 3, totalSteps: 4, labels: const ['Date/Time', 'Services', 'Summary', 'Payment']),
          const SizedBox(height: 20),
          _amountCard(total, args),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Select Payment Method'),
          ..._methods.map((m) => _buildMethodTile(m)),
          const SizedBox(height: 14),
          InfoBanner(
            message: 'All payments are SSL encrypted and processed securely.',
            bgColor: AppTheme.warningLight,
            textColor: AppTheme.adminPrimary,
            icon: Icons.security_outlined,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _navigateToMethod(context, args, total),
            child: const Text('Continue to Payment'),
          ),
        ]),
      ),
    );
  }

  Widget _amountCard(double total, Map<String, dynamic> args) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primaryLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Amount due', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          const SizedBox(height: 4),
          Text('RM ${total.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.primary)),
          const SizedBox(height: 4),
          Text('${args['name'] ?? 'Grand Ballroom A'} · ${args['date'] ?? '15 Apr 2025'}',
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        ]),
      );

  Widget _buildMethodTile((String, String, String, String, Color, Color) m) {
    final (key, abbrev, title, subtitle, fg, bg) = m;
    final isSelected = _selected == key;
    return GestureDetector(
      onTap: () => setState(() => _selected = key),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryLight : Colors.white,
          border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.cardBorder, width: isSelected ? 1.5 : 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Container(
            width: 20, height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? AppTheme.primary : Colors.white,
              border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.cardBorder, width: 1.5),
            ),
            child: isSelected ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
          ),
          const SizedBox(width: 12),
          Container(
            width: 44, height: 30,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
            child: Center(child: Text(abbrev, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ])),
          if (isSelected) const Icon(Icons.chevron_right, color: AppTheme.primary, size: 18),
        ]),
      ),
    );
  }

  void _navigateToMethod(BuildContext context, Map<String, dynamic> args, double total) {
    final newArgs = {...args, 'paymentMethod': _selected, 'totalPrice': total};
    if (_selected == 'fpx') {
      Navigator.pushNamed(context, '/payment/processing', arguments: {...newArgs, 'bank': 'FPX'});
    } else if (_selected == 'card') {
      _showCardSheet(context, newArgs);
    } else {
      _showEWalletSheet(context, newArgs);
    }
  }

  void _showCardSheet(BuildContext context, Map<String, dynamic> args) =>
      showModalBottomSheet(
        context: context, isScrollControlled: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => _CardPaymentSheet(args: args),
      );

  void _showEWalletSheet(BuildContext context, Map<String, dynamic> args) =>
      showModalBottomSheet(
        context: context, isScrollControlled: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => _EWalletSheet(args: args, method: _selected),
      );
}

// ── Inline Card Payment Sheet ────────────────────────────────────────────────
class _CardPaymentSheet extends StatefulWidget {
  final Map<String, dynamic> args;
  const _CardPaymentSheet({required this.args});
  @override
  State<_CardPaymentSheet> createState() => _CardPaymentSheetState();
}

class _CardPaymentSheetState extends State<_CardPaymentSheet> {
  bool _saveCard = true;
  final _cardCtrl = TextEditingController(text: '');
  final _nameCtrl = TextEditingController(text: 'Ahmad Hassan');
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.cardBorder, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Text('Card Payment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            _cardPreview(),
            const SizedBox(height: 16),
            TextFormField(controller: _cardCtrl, decoration: const InputDecoration(labelText: 'Card number', hintText: '1234 5678 9012 3456'), keyboardType: TextInputType.number),
            const SizedBox(height: 10),
            TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Cardholder name')),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: TextFormField(controller: _expiryCtrl, decoration: const InputDecoration(labelText: 'Expiry (MM/YY)'), keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: TextFormField(controller: _cvvCtrl, decoration: const InputDecoration(labelText: 'CVV'), keyboardType: TextInputType.number, obscureText: true)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Checkbox(value: _saveCard, onChanged: (v) => setState(() => _saveCard = v!), activeColor: AppTheme.primary),
              const Text('Save card for future bookings', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            ]),
            InfoBanner(message: 'Secured by 3D Secure · SSL encrypted', bgColor: AppTheme.successLight, textColor: AppTheme.success, icon: Icons.security),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/payment/processing', arguments: widget.args);
              },
              child: Text('Pay RM ${(widget.args['totalPrice'] as double? ?? 11600).toStringAsFixed(2)}'),
            ),
          ]),
        ),
      );

  Widget _cardPreview() => Container(
        width: double.infinity, height: 140,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppTheme.primary, Color(0xFF0C447C)]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('EventSpace', style: TextStyle(color: Color(0xFFB5D4F4), fontSize: 12, fontWeight: FontWeight.w600)),
            Container(width: 28, height: 20, decoration: BoxDecoration(color: const Color(0xFFEF9F27), borderRadius: BorderRadius.circular(4))),
          ]),
          const Text('•••• •••• •••• ____', style: TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 3, fontWeight: FontWeight.w600)),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('CARDHOLDER', style: TextStyle(color: Color(0xFFB5D4F4), fontSize: 9)),
              Text(_nameCtrl.text.isEmpty ? 'FULL NAME' : _nameCtrl.text.toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            ]),
            Row(children: [
              Container(width: 24, height: 24, decoration: const BoxDecoration(color: Color(0xFFE24B4A), shape: BoxShape.circle)),
              Transform.translate(offset: const Offset(-10, 0), child: Container(width: 24, height: 24,
                  decoration: const BoxDecoration(color: Color(0xFFEF9F27), shape: BoxShape.circle))),
            ]),
          ]),
        ]),
      );
}

// ── e-Wallet Sheet ────────────────────────────────────────────────────────────
class _EWalletSheet extends StatelessWidget {
  final Map<String, dynamic> args;
  final String method;
  const _EWalletSheet({required this.args, required this.method});

  @override
  Widget build(BuildContext context) {
    final name = method == 'tng' ? "Touch 'n Go" : 'GrabPay';
    final total = (args['totalPrice'] as double?) ?? 11600.0;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppTheme.cardBorder, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text('$name Payment', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16), width: double.infinity,
            decoration: BoxDecoration(color: AppTheme.primaryLight, borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              Text('Paying via $name', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              const SizedBox(height: 4),
              Text('RM ${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppTheme.primary)),
              const Text('Wallet balance: RM 12,450.00', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ]),
          ),
          const SizedBox(height: 20),
          Container(
            width: 120, height: 120,
            decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.cardBorder)),
            child: const Center(child: Icon(Icons.qr_code_2, size: 80, color: Color(0xFF1E293B))),
          ),
          const SizedBox(height: 8),
          const Text('Scan QR with app', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const Text('or', style: TextStyle(color: AppTheme.textTertiary)),
          const SizedBox(height: 8),
          TextFormField(decoration: InputDecoration(hintText: 'Enter $name registered phone no.')),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/payment/processing', arguments: args);
            },
            child: const Text('Request payment link'),
          ),
          const SizedBox(height: 8),
          const Text('QR expires in 10:00 min', style: TextStyle(fontSize: 12, color: AppTheme.textTertiary)),
        ]),
      ),
    );
  }
}
