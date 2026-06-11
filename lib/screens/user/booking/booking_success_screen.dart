import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/shared_widgets.dart';

class BookingSuccessScreen extends StatelessWidget {
  const BookingSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            const SizedBox(height: 20),
            Container(
              width: 72, height: 72,
              decoration: const BoxDecoration(color: AppTheme.successLight, shape: BoxShape.circle),
              child: const Icon(Icons.check, size: 36, color: AppTheme.success),
            ),
            const SizedBox(height: 16),
            const Text('Booking Confirmed!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text('Ref: BK-20250415-0032', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
            const SizedBox(height: 24),
            _summaryCard(args),
            const SizedBox(height: 14),
            InfoBanner(
              message: 'Confirmation email sent · PDF receipt attached',
              bgColor: AppTheme.successLight,
              textColor: AppTheme.success,
              icon: Icons.email_outlined,
            ),
            const SizedBox(height: 10),
            InfoBanner(
              message: 'Push notification sent · Reminder 24h before event',
              bgColor: AppTheme.primaryLight,
              textColor: AppTheme.primaryDark,
              icon: Icons.notifications_outlined,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/user/my-bookings', (_) => false),
              child: const Text('View My Bookings'),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/user/home', (_) => false),
              child: const Text('Back to Home'),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _summaryCard(Map<String, dynamic> args) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: const Row(children: [
              Icon(Icons.receipt_long_outlined, size: 16, color: AppTheme.textSecondary),
              SizedBox(width: 8),
              Text('BOOKING SUMMARY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                  letterSpacing: 0.5, color: AppTheme.textSecondary)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(children: [
              PriceRow(label: 'Hall', value: args['name'] ?? 'Grand Ballroom A'),
              PriceRow(label: 'Date', value: args['date'] ?? '15 Apr 2025'),
              PriceRow(label: 'Time', value: args['slot'] ?? '10:00–12:00'),
              PriceRow(label: 'Guests', value: '${args['guestCount'] ?? 200} pax'),
              PriceRow(label: 'Add-ons', value: 'Buffet, Projector'),
              const Divider(height: 16),
              PriceRow(label: 'Total paid', value: 'RM ${(args['totalPrice'] as double? ?? 11600).toStringAsFixed(0)}', isTotal: true),
              const SizedBox(height: 4),
              PriceRow(label: 'Payment method', value: 'Maybank FPX'),
            ]),
          ),
        ]),
      );
}
