import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/shared_widgets.dart';
import '../../../services/app_events.dart';
import '../../../services/db_service.dart';
import '../../../services/session_service.dart';

class MyBookingsScreen extends StatefulWidget {
  final bool isTab;
  const MyBookingsScreen({super.key, this.isTab = false});
  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  int _navIndex = 2, _filterIndex = 0;
  bool _isLoading = false;
  List<Map<String, dynamic>> _bookings = [];
  final _filters = ['All', 'Upcoming', 'Past', 'Cancelled'];
  final _dbService = DbService();

  @override
  void initState() {
    super.initState();
    _loadBookings();
    // Reload whenever bookings change in any tab so the list and the
    // profile stats always reflect the same underlying data.
    AppEvents.dataVersion.addListener(_loadBookings);
  }

  @override
  void dispose() {
    AppEvents.dataVersion.removeListener(_loadBookings);
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    try {
      final bookings = await _dbService.getMyBookings(SessionService.instance.email);
      if (mounted) {
        setState(() {
          _bookings = bookings.map(_normalize).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _bookings = [];
          _isLoading = false;
        });
      }
    }
  }

  // Map a raw Firestore booking document into the shape the card expects.
  // Firestore stores hallName/timeSlot/amount; the UI reads hall/time/price.
  Map<String, dynamic> _normalize(Map<String, dynamic> b) {
    final status = (b['status'] ?? 'Pending').toString();
    const statusTypes = {
      'Confirmed': 'success',
      'Pending': 'warning',
      'Cancelled': 'danger',
      'Completed': 'neutral',
    };
    final amount = (b['amount'] is num) ? (b['amount'] as num).toDouble() : 0.0;
    return {
      'id': (b['id'] ?? '').toString(),
      'ref': (b['ref'] ?? b['id'] ?? '').toString(),
      'hall': b['hallName'] ?? b['hall'] ?? 'Unknown Hall',
      'date': b['date'] ?? '-',
      'time': b['timeSlot'] ?? b['time'] ?? '-',
      'price': 'RM ${amount.toStringAsFixed(0)}',
      'status': status,
      'statusType': statusTypes[status] ?? 'info',
      'upcoming': b['upcoming'] ?? (status == 'Confirmed' || status == 'Pending'),
    };
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filterIndex == 0) return _bookings;
    if (_filterIndex == 1) return _bookings.where((b) => b['upcoming'] == true).toList();
    if (_filterIndex == 2) return _bookings.where((b) => b['status'] == 'Completed').toList();
    return _bookings.where((b) => b['status'] == 'Cancelled').toList();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('My Bookings'),
          automaticallyImplyLeading: !widget.isTab,
        ),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: FilterChipRow(chips: _filters, selected: _filterIndex,
                onSelected: (i) => setState(() => _filterIndex = i)),
          ),
          const SizedBox(height: 4),
          Expanded(child: RefreshIndicator(
            onRefresh: _loadBookings,
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
                ? const Center(child: Text('No bookings found', style: TextStyle(color: AppTheme.textSecondary)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) => _buildCard(_filtered[i]),
                  ),
          )),
        ]),
        bottomNavigationBar: widget.isTab ? null : UserBottomNav(
          currentIndex: _navIndex,
          onTap: (i) {
            setState(() => _navIndex = i);
            if (i == 0) Navigator.pushReplacementNamed(context, '/user/home');
          },
        ),
      );

  Widget _buildCard(Map<String, dynamic> b) {
    final statusTypeMap = {
      'success': StatusType.success, 'warning': StatusType.warning,
      'danger': StatusType.danger, 'neutral': StatusType.neutral,
    };
    final st = statusTypeMap[b['statusType']] ?? StatusType.info;
    final isUpcoming = b['upcoming'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(b['hall']!, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            StatusBadge(label: b['status']!, type: st),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.textSecondary),
            const SizedBox(width: 4),
            Text(b['date']!, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            const SizedBox(width: 12),
            const Icon(Icons.access_time_outlined, size: 14, color: AppTheme.textSecondary),
            const SizedBox(width: 4),
            Text(b['time']!, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            Text('Ref: ${b['ref']}', style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary)),
            const Spacer(),
            Text(b['price']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.primary)),
          ]),
          if (isUpcoming) ...[
            const Divider(height: 18),
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: () async {
                  await Navigator.pushNamed(context, '/user/edit-booking', arguments: b);
                  _loadBookings();
                },
                icon: const Icon(Icons.edit_outlined, size: 14),
                label: const Text('Edit', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 8)),
              )),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton.icon(
                onPressed: () => _confirmCancel(context, b),
                icon: const Icon(Icons.cancel_outlined, size: 14, color: AppTheme.danger),
                label: const Text('Cancel', style: TextStyle(fontSize: 12, color: AppTheme.danger)),
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    side: const BorderSide(color: AppTheme.danger)),
              )),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/payment/history'),
                icon: const Icon(Icons.receipt_outlined, size: 14, color: AppTheme.textSecondary),
                label: const Text('Receipt', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    side: BorderSide(color: AppTheme.cardBorder)),
              )),
            ]),
          ] else if (b['status'] == 'Completed') ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.star_border, size: 14, color: AppTheme.success),
              label: const Text('Leave a review', style: TextStyle(fontSize: 12, color: AppTheme.success)),
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
            ),
          ],
        ]),
      ),
    );
  }

  void _confirmCancel(BuildContext context, Map<String, dynamic> b) => showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Cancel booking?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('This will cancel ${b['ref']} for ${b['hall']} on ${b['date']}.',
                style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
            const SizedBox(height: 12),
            InfoBanner(
              message: 'Free cancellation if 48h before event.',
              bgColor: AppTheme.dangerLight,
              textColor: AppTheme.danger,
              icon: Icons.warning_amber_outlined,
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Keep booking')),
            ElevatedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(context);
                final ok = await _dbService.updateBookingStatus(
                    b['id'].toString(), 'Cancelled');
                if (ok) await _loadBookings();
                messenger.showSnackBar(SnackBar(
                    content: Text(ok
                        ? 'Booking cancelled successfully'
                        : 'Failed to cancel booking'),
                    backgroundColor: AppTheme.danger));
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
              child: const Text('Yes, cancel'),
            ),
          ],
        ),
      );
}
