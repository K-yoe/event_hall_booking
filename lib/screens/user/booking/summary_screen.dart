import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/shared_widgets.dart';
import '../../../services/session_service.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({super.key});
  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  bool _confirmed = false;

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    final total = (args['totalPrice'] as double?) ?? 2500.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review & Confirm'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          BookingProgressBar(currentStep: 2, totalSteps: 4, labels: const ['Date/Time', 'Services', 'Summary', 'Payment']),
          const SizedBox(height: 20),
          _buildSummaryCard(args, total),
          const SizedBox(height: 16),
          _buildPersonalDetails(),
          const SizedBox(height: 16),
          _buildCancellationPolicy(),
          const SizedBox(height: 16),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Checkbox(
              value: _confirmed,
              onChanged: (v) => setState(() => _confirmed = v!),
              activeColor: AppTheme.primary,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 6),
            const Expanded(child: Text(
              'I confirm that all the booking details above are correct and I agree to the cancellation policy.',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4),
            )),
          ]),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _confirmed
                ? () => Navigator.pushNamed(context, '/payment/method', arguments: args)
                : null,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.lock_outline, size: 16),
              const SizedBox(width: 8),
              Text('Proceed to Payment  RM ${total.toStringAsFixed(0)}'),
            ]),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Edit Booking'),
          ),
        ]),
      ),
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic> args, double total) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: const Row(children: [
              Icon(Icons.receipt_long_outlined, size: 18, color: AppTheme.textSecondary),
              SizedBox(width: 8),
              Text('BOOKING SUMMARY', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  letterSpacing: 0.5, color: AppTheme.textSecondary)),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(children: [
              PriceRow(label: 'Hall', value: args['name'] ?? 'Grand Ballroom A'),
              PriceRow(label: 'Location', value: args['location'] ?? 'KL Sentral'),
              PriceRow(label: 'Date', value: args['date'] ?? '15 April 2025'),
              PriceRow(label: 'Time slot', value: args['slot'] ?? '10:00–12:00'),
              PriceRow(label: 'Expected guests', value: '${args['guestCount'] ?? 100} pax'),
              PriceRow(label: 'Hall base price', value: 'RM 2,500'),
              const Divider(height: 20),
              PriceRow(label: 'Total', value: 'RM ${total.toStringAsFixed(0)}', isTotal: true),
            ]),
          ),
        ]),
      );

  Widget _buildPersonalDetails() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader(title: 'Your Details'),
        TextFormField(
          initialValue: SessionService.instance.name,
          decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline, size: 18)),
        ),
        const SizedBox(height: 10),
        TextFormField(
          initialValue: SessionService.instance.email,
          decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined, size: 18)),
        ),
        const SizedBox(height: 10),
        TextFormField(
          initialValue: 'Annual Company Gala',
          decoration: const InputDecoration(labelText: 'Event name / purpose', prefixIcon: Icon(Icons.event_outlined, size: 18)),
        ),
      ]);

  Widget _buildCancellationPolicy() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF9EC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFFAC775)),
        ),
        child: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.info_outline, size: 16, color: Color(0xFF633806)),
            SizedBox(width: 8),
            Text('Cancellation policy', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF633806))),
          ]),
          SizedBox(height: 6),
          Text('Free cancellation if made 48 hours before the event. Cancellations within 48 hours are subject to a 50% charge.',
              style: TextStyle(fontSize: 12, color: Color(0xFF854F0B), height: 1.4)),
        ]),
      );
}
