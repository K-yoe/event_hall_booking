import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/shared_widgets.dart';
import '../../../services/db_service.dart';

class EditBookingScreen extends StatefulWidget {
  const EditBookingScreen({super.key});
  @override
  State<EditBookingScreen> createState() => _EditBookingScreenState();
}

class _EditBookingScreenState extends State<EditBookingScreen> {
  final _db = DbService();
  bool _buffet = true, _projector = true, _photographer = false;
  double get _total {
    double t = 2500;
    if (_buffet) t += 9000;
    if (_projector) t += 100;
    if (_photographer) t += 500;
    return t;
  }

  @override
  Widget build(BuildContext context) {
    final b = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Booking'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          InfoBanner(
            message: 'Editing: ${b['ref'] ?? 'BK-20250415-0032'}  ·  ${b['hall'] ?? 'Grand Ballroom A'}',
            bgColor: AppTheme.warningLight,
            textColor: AppTheme.adminPrimary,
            icon: Icons.edit_outlined,
          ),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Change Date / Time'),
          _changeDateCard(),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Update Add-on Services'),
          _serviceRow('☕ Lunch Buffet (200 pax)', 'RM 9,000', _buffet, (v) => setState(() => _buffet = v)),
          _serviceRow('📽 Projector + Screen', 'RM 100', _projector, (v) => setState(() => _projector = v)),
          _serviceRow('📸 Event Photographer', '+RM 500', _photographer, (v) => setState(() => _photographer = v)),
          const SizedBox(height: 20),
          _totalCard(),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              final id = (b['id'] ?? '').toString();
              final ok = id.isEmpty
                  ? false
                  : await _db.updateBooking(id, {'amount': _total});
              messenger.showSnackBar(SnackBar(
                  content: Text(ok
                      ? 'Booking updated successfully!'
                      : 'Could not update booking'),
                  backgroundColor: ok ? AppTheme.success : AppTheme.danger));
              if (ok) navigator.pop();
            },
            child: const Text('Save Changes'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Discard'),
          ),
        ]),
      ),
    );
  }

  Widget _changeDateCard() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Row(children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Current: 15 Apr 2025, 10:00–12:00',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/user/date-time'),
              child: const Text('Tap to change date/time →',
                  style: TextStyle(fontSize: 13, color: AppTheme.primary, fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline)),
            ),
          ]),
        ]),
      );

  Widget _serviceRow(String name, String price, bool checked, ValueChanged<bool> onChange) =>
      GestureDetector(
        onTap: () => onChange(!checked),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: checked ? AppTheme.primaryLight : Colors.white,
            border: Border.all(color: checked ? AppTheme.primary : AppTheme.cardBorder, width: checked ? 1.5 : 0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(children: [
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                color: checked ? AppTheme.primary : Colors.white,
                border: Border.all(color: checked ? AppTheme.primary : AppTheme.cardBorder, width: 1.5),
                borderRadius: BorderRadius.circular(5),
              ),
              child: checked ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
            Text(price, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: checked ? AppTheme.primary : AppTheme.textSecondary)),
          ]),
        ),
      );

  Widget _totalCard() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Updated total', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          Text('RM ${_total.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.primary)),
        ]),
      );
}
