import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/shared_widgets.dart';
import '../../../services/db_service.dart';

class DateTimeScreen extends StatefulWidget {
  const DateTimeScreen({super.key});
  @override
  State<DateTimeScreen> createState() => _DateTimeScreenState();
}

class _DateTimeScreenState extends State<DateTimeScreen> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  DateTime _focusedMonth = DateTime.now();
  int _selectedSlot = -1;

  final _slots = ['08:00–10:00', '10:00–12:00', '12:00–14:00', '14:00–16:00', '16:00–18:00', '18:00–20:00'];
  Set<int> _takenSlots = {};

  final _db = DbService();
  Map<String, dynamic> _hall = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _hall = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {};
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    final name = (_hall['name'] ?? '').toString();
    if (name.isEmpty) return;
    final booked = await _db.getBookedSlots(name, _formatDate(_selectedDate));
    if (!mounted) return;
    setState(() {
      _takenSlots = {
        for (int i = 0; i < _slots.length; i++)
          if (booked.contains(_slots[i])) i
      };
    });
  }

  String _formatDate(DateTime d) => '${d.day} ${_monthName(d.month)} ${d.year}';

  @override
  Widget build(BuildContext context) {
    final hall = _hall;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Date & Time'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18), onPressed: () => Navigator.pop(context)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          BookingProgressBar(currentStep: 0, totalSteps: 4, labels: const ['Date/Time', 'Services', 'Summary', 'Payment']),
          const SizedBox(height: 20),
          _buildCalendar(),
          const SizedBox(height: 20),
          const SectionHeader(title: 'Available Time Slots'),
          _buildSlotLegend(),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 3, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 2.4,
            children: List.generate(_slots.length, (i) => _buildSlot(i)),
          ),
          const SizedBox(height: 16),
          InfoBanner(
            message: 'Past dates and already-booked slots are locked.',
            bgColor: const Color(0xFFFFF9EC),
            textColor: const Color(0xFF633806),
            icon: Icons.lock_outline,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _selectedSlot >= 0 ? () => Navigator.pushNamed(context, '/user/services',
                arguments: {...hall, 'date': _formatDate(_selectedDate), 'slot': _slots[_selectedSlot]}) : null,
            child: const Text('Next — Add Services'),
          ),
        ]),
      ),
    );
  }

  Widget _buildCalendar() {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7;
    final today = DateTime.now();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () => setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1)),
          ),
          Text(
            '${_monthName(_focusedMonth.month)} ${_focusedMonth.year}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: () => setState(() => _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1)),
          ),
        ]),
        const SizedBox(height: 8),
        Row(children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((d) => Expanded(
              child: Center(child: Text(d, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textTertiary))),
            )).toList()),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 1),
          itemCount: startWeekday + daysInMonth,
          itemBuilder: (_, index) {
            if (index < startWeekday) return const SizedBox();
            final day = index - startWeekday + 1;
            final date = DateTime(_focusedMonth.year, _focusedMonth.month, day);
            final isPast = date.isBefore(DateTime(today.year, today.month, today.day));
            final isSelected = _selectedDate.year == date.year &&
                _selectedDate.month == date.month && _selectedDate.day == date.day;
            return GestureDetector(
              onTap: isPast ? null : () {
                setState(() { _selectedDate = date; _selectedSlot = -1; });
                _loadAvailability();
              },
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text('$day', style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? Colors.white : isPast ? AppTheme.textTertiary : const Color(0xFF1E293B))),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          'Selected: ${_selectedDate.day} ${_monthName(_selectedDate.month)} ${_selectedDate.year}',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppTheme.primary),
        ),
      ]),
    );
  }

  Widget _buildSlot(int i) {
    final isTaken = _takenSlots.contains(i);
    final isSelected = _selectedSlot == i;
    return GestureDetector(
      onTap: isTaken ? null : () => setState(() => _selectedSlot = i),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryLight : isTaken ? AppTheme.surface : Colors.white,
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.cardBorder,
            width: isSelected ? 1.5 : 0.5,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            _slots[i],
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? AppTheme.primary : isTaken ? AppTheme.textTertiary : const Color(0xFF1E293B),
              decoration: isTaken ? TextDecoration.lineThrough : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSlotLegend() => Row(children: [
        _legendItem(Colors.white, AppTheme.cardBorder, 'Available', AppTheme.textSecondary),
        const SizedBox(width: 12),
        _legendItem(AppTheme.primaryLight, AppTheme.primary, 'Selected', AppTheme.primary),
        const SizedBox(width: 12),
        _legendItem(AppTheme.surface, AppTheme.cardBorder, 'Taken', AppTheme.textTertiary, lineThrough: true),
      ]);

  Widget _legendItem(Color bg, Color border, String label, Color textColor, {bool lineThrough = false}) =>
      Row(children: [
        Container(
          width: 16, height: 16,
          decoration: BoxDecoration(color: bg, border: Border.all(color: border), borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: textColor, decoration: lineThrough ? TextDecoration.lineThrough : null)),
      ]);

  String _monthName(int m) => ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m - 1];
}
