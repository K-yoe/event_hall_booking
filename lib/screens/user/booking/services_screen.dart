import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/shared_widgets.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});
  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final Map<String, bool> _selected = {
    'catering_lunch': false, 'catering_hitea': false,
    'av_projector': false, 'av_mic': false,
    'photographer': false, 'live_streaming': false,
  };
  int _guestCount = 100;

  double _basePrice = 2500.0;
  bool _baseInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_baseInit) return;
    _baseInit = true;
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    final perDay = args['price_per_day'];
    final perHr = args['price_per_hr'];
    if (perDay is num && perDay > 0) {
      _basePrice = perDay.toDouble();
    } else if (perHr is num && perHr > 0) {
      _basePrice = perHr.toDouble();
    }
  }

  static const _services = {
    'catering_lunch': ('☕ Lunch Buffet Set', 'Min 50 pax, halal certified', 45.0, true),
    'catering_hitea': ('🍵 Morning Hi-Tea', 'Min 20 pax', 25.0, true),
    'av_projector': ('📽 Projector + Screen', '4K ready, HDMI / wireless', 100.0, false),
    'av_mic': ('🎤 Wireless Microphones ×4', 'Handheld + lapel', 80.0, false),
    'photographer': ('📸 Event Photographer', 'Full-day coverage', 500.0, false),
    'live_streaming': ('📡 Live Streaming Setup', 'YouTube / Zoom ready', 350.0, false),
  };

  double get _total {
    double t = _basePrice;
    _selected.forEach((k, v) {
      if (!v) return;
      final (_, _, price, perPax) = _services[k]!;
      t += perPax ? price * _guestCount : price;
    });
    return t;
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add-on Services'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18), onPressed: () => Navigator.pop(context)),
      ),
      body: Column(children: [
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            BookingProgressBar(currentStep: 1, totalSteps: 4, labels: const ['Date/Time', 'Services', 'Summary', 'Payment']),
            const SizedBox(height: 20),
            _guestCountRow(),
            const SizedBox(height: 20),
            const SectionHeader(title: 'Catering'),
            _buildService('catering_lunch'),
            _buildService('catering_hitea'),
            const SectionHeader(title: 'AV Equipment'),
            _buildService('av_projector'),
            _buildService('av_mic'),
            const SectionHeader(title: 'Other Services'),
            _buildService('photographer'),
            _buildService('live_streaming'),
          ]),
        )),
        _buildPricePanel(args),
      ]),
    );
  }

  Widget _guestCountRow() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Row(children: [
          const Icon(Icons.people_outline, color: AppTheme.textSecondary),
          const SizedBox(width: 10),
          const Text('Expected guests', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, color: AppTheme.primary),
            onPressed: () => setState(() => _guestCount = (_guestCount - 10).clamp(10, 1000)),
          ),
          Text('$_guestCount', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary),
            onPressed: () => setState(() => _guestCount = (_guestCount + 10).clamp(10, 1000)),
          ),
        ]),
      );

  Widget _buildService(String key) {
    final (name, desc, price, perPax) = _services[key]!;
    final isChecked = _selected[key]!;
    return GestureDetector(
      onTap: () => setState(() => _selected[key] = !isChecked),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isChecked ? AppTheme.primaryLight : Colors.white,
          border: Border.all(color: isChecked ? AppTheme.primary : AppTheme.cardBorder, width: isChecked ? 1.5 : 0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          Container(
            width: 22, height: 22,
            decoration: BoxDecoration(
              color: isChecked ? AppTheme.primary : Colors.white,
              border: Border.all(color: isChecked ? AppTheme.primary : AppTheme.cardBorder, width: 1.5),
              borderRadius: BorderRadius.circular(5),
            ),
            child: isChecked ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            Text(desc, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ])),
          Text(
            perPax ? '+RM ${price.toInt()}/pax' : '+RM ${price.toInt()}',
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: isChecked ? AppTheme.primary : AppTheme.textSecondary),
          ),
        ]),
      ),
    );
  }

  Widget _buildPricePanel(Map<String, dynamic> args) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppTheme.cardBorder)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        child: Column(children: [
          Row(children: [
            const Text('Hall base', style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            const Spacer(),
            Text('RM ${_basePrice.toInt()}', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          ]),
          ..._selected.entries.where((e) => e.value).map((e) {
            final (name, _, price, perPax) = _services[e.key]!;
            final amt = perPax ? price * _guestCount : price;
            return Row(children: [
              Expanded(child: Text(name, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary), overflow: TextOverflow.ellipsis)),
              Text('RM ${amt.toInt()}', style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ]);
          }),
          const Divider(height: 14),
          Row(children: [
            const Text('Running total', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const Spacer(),
            Text('RM ${_total.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.primary)),
          ]),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/user/summary', arguments: {
              ...args,
              'services': Map.of(_selected),
              'guestCount': _guestCount,
              'totalPrice': _total,
            }),
            child: const Text('Next — Review Summary'),
          ),
        ]),
      );
}
