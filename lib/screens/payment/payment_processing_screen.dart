import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../services/db_service.dart';
import '../../services/session_service.dart';

// ── Processing Screen ─────────────────────────────────────────────────────────
class PaymentProcessingScreen extends StatefulWidget {
  const PaymentProcessingScreen({super.key});
  @override
  State<PaymentProcessingScreen> createState() => _PaymentProcessingScreenState();
}

class _PaymentProcessingScreenState extends State<PaymentProcessingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final _dbService = DbService();

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
    _processPayment();
  }

  Future<void> _processPayment() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    
    // 80% chance success for demo
    final isSuccess = DateTime.now().millisecondsSinceEpoch % 5 != 0;

    if (isSuccess) {
      // Save booking + payment record to the local database on success
      final session = SessionService.instance;
      final now = DateTime.now();
      final ref = 'BK-${now.millisecondsSinceEpoch}';
      final amount = (args['totalPrice'] as num?)?.toDouble() ?? 0.0;
      final method = _methodName(args['paymentMethod'] ?? 'fpx');

      await _dbService.createBooking({
        'ref': ref,
        'hallId': (args['id'] ?? args['hallId'] ?? '').toString(),
        'hallName': args['name'],
        'userName': session.name,
        'userEmail': session.email,
        'date': args['date'],
        'timeSlot': args['slot'],
        'amount': amount,
        'status': 'Confirmed',
        'upcoming': true,
      });

      await _dbService.createPayment({
        'txn': 'TXN-${now.millisecondsSinceEpoch}',
        'bookingRef': ref,
        'userName': session.name,
        'userEmail': session.email,
        'hallName': args['name'],
        'amount': amount,
        'method': method,
        'status': 'Paid',
        'date': _formatDateTime(now),
      });
      Navigator.pushReplacementNamed(context, '/payment/success', arguments: args);
    } else {
      Navigator.pushReplacementNamed(context, '/payment/failed', arguments: args);
    }
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    final total = (args['totalPrice'] as double?) ?? 11600.0;
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              RotationTransition(
                turns: _ctrl,
                child: Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primary, width: 4),
                  ),
                  child: const SizedBox(),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Processing payment...', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('Please do not close or press back.\nWe are processing your transaction securely.',
                  textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.5)),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.cardBorder)),
                child: Column(children: [
                  PriceRow(label: 'Amount', value: 'RM ${total.toStringAsFixed(2)}'),
                  PriceRow(label: 'Method', value: _methodName(args['paymentMethod'] ?? 'fpx')),
                  PriceRow(label: 'Reference', value: 'TXN-20250415-8821'),
                ]),
              ),
              const SizedBox(height: 24),
              const Text('Contacting secure server...', style: TextStyle(fontSize: 12, color: AppTheme.textTertiary)),
            ]),
          ),
        ),
      ),
    );
  }

  String _methodName(String m) => {'fpx': 'FPX Online Banking', 'card': 'Credit Card', 'tng': 'Touch \'n Go', 'grab': 'GrabPay', 'bank': 'Bank Transfer'}[m] ?? m;

  static String _formatDateTime(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final ampm = d.hour < 12 ? 'AM' : 'PM';
    final mm = d.minute.toString().padLeft(2, '0');
    return '${d.day} ${months[d.month - 1]} ${d.year}, $h:$mm $ampm';
  }
}

// ── Success Screen ────────────────────────────────────────────────────────────
class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    final total = (args['totalPrice'] as double?) ?? 11600.0;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            const SizedBox(height: 16),
            Container(
              width: 72, height: 72,
              decoration: const BoxDecoration(color: AppTheme.successLight, shape: BoxShape.circle),
              child: const Icon(Icons.check, size: 38, color: AppTheme.success),
            ),
            const SizedBox(height: 14),
            const Text('Payment Successful!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            const Text('Transaction ref: TXN-20250415-8821',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            const SizedBox(height: 24),
            _receiptCard(args, total),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                label: const Text('Download PDF', style: TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
              )),
              const SizedBox(width: 10),
              Expanded(child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.share_outlined, size: 16, color: AppTheme.textSecondary),
                label: const Text('Share', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    side: const BorderSide(color: AppTheme.cardBorder)),
              )),
            ]),
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/user/my-bookings', (_) => false),
              child: const Text('View My Bookings'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/user/home', (_) => false),
              child: const Text('Back to Home'),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _receiptCard(Map<String, dynamic> args, double total) => Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.cardBorder)),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(14))),
            child: const Row(children: [
              Icon(Icons.receipt_long, size: 16, color: AppTheme.textSecondary),
              SizedBox(width: 8),
              Text('OFFICIAL RECEIPT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: AppTheme.textSecondary)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(children: [
              PriceRow(label: 'Booking ref', value: 'BK-20250415-0032'),
              PriceRow(label: 'Hall', value: args['name'] ?? 'Grand Ballroom A'),
              PriceRow(label: 'Date', value: args['date'] ?? '15 Apr 2025'),
              PriceRow(label: 'Time', value: args['slot'] ?? '10:00–12:00'),
              PriceRow(label: 'Hall base', value: 'RM 2,500'),
              PriceRow(label: 'Catering (200 pax)', value: 'RM 9,000'),
              PriceRow(label: 'Projector', value: 'RM 100'),
              PriceRow(label: 'SST (0%)', value: 'RM 0'),
              const Divider(height: 16),
              PriceRow(label: 'Total paid', value: 'RM ${total.toStringAsFixed(2)}', isTotal: true),
              PriceRow(label: 'Method', value: 'Maybank FPX'),
              PriceRow(label: 'Paid on', value: '15 Apr 2025, 9:43 AM'),
            ]),
          ),
        ]),
      );
}

// ── Failed Screen ─────────────────────────────────────────────────────────────
class PaymentFailedScreen extends StatelessWidget {
  const PaymentFailedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    final total = (args['totalPrice'] as double?) ?? 11600.0;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 72, height: 72,
              decoration: const BoxDecoration(color: AppTheme.dangerLight, shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 38, color: AppTheme.danger),
            ),
            const SizedBox(height: 16),
            const Text('Payment Failed', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('Your transaction could not be completed.\nNo charges were made to your account.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.5)),
            const SizedBox(height: 24),
            Container(
              width: double.infinity, padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppTheme.dangerLight, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3))),
              child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Reason', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.danger)),
                SizedBox(height: 4),
                Text('Bank declined: Insufficient funds or session timeout. Please try again or use a different method.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF791F1F), height: 1.4)),
              ]),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppTheme.cardBorder)),
              child: Column(children: [
                PriceRow(label: 'Amount', value: 'RM ${total.toStringAsFixed(2)}'),
                PriceRow(label: 'Reference', value: 'TXN-20250415-8821'),
              ]),
            ),
            const SizedBox(height: 8),
            InfoBanner(
              message: 'Booking held for 15 min. Contact support if issue persists.',
              bgColor: AppTheme.warningLight,
              textColor: AppTheme.adminPrimary,
              icon: Icons.timer_outlined,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/payment/method', arguments: args),
              child: const Text('Try Again'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/payment/method', arguments: args),
              child: const Text('Change Payment Method'),
            ),
          ]),
        ),
      ),
    );
  }
}
