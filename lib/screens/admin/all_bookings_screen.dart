import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../services/db_service.dart';

class AllBookingsScreen extends StatefulWidget {
  const AllBookingsScreen({super.key});
  @override
  State<AllBookingsScreen> createState() => _AllBookingsScreenState();
}

class _AllBookingsScreenState extends State<AllBookingsScreen> {
  int _filterIndex = 0;
  String _search = '';
  bool _isLoading = false;
  final _filters = ['All', 'Confirmed', 'Pending', 'Cancelled', 'Completed'];
  final _dbService = DbService();

  List<Map<String, dynamic>> _bookings = [];

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    final rows = await _dbService.getAllBookings();
    if (!mounted) return;
    setState(() {
      _bookings = rows.map(_normalize).toList();
      _isLoading = false;
    });
  }

  Map<String, dynamic> _normalize(Map<String, dynamic> b) {
    final status = (b['status'] ?? 'Pending').toString();
    const statusTypes = {
      'Confirmed': 'success', 'Pending': 'warning',
      'Cancelled': 'danger', 'Completed': 'neutral',
    };
    final amount = (b['amount'] is num) ? (b['amount'] as num).toDouble() : 0.0;
    return {
      'id': (b['id'] ?? '').toString(),
      'ref': b['ref'] ?? '',
      'user': b['userName'] ?? '-',
      'hall': b['hallName'] ?? '-',
      'date': b['date'] ?? '-',
      'time': b['timeSlot'] ?? '-',
      'price': 'RM ${amount.toStringAsFixed(0)}',
      'status': status,
      'statusType': statusTypes[status] ?? 'info',
    };
  }

  List<Map<String, dynamic>> get _filtered {
    var list = _filterIndex == 0 ? _bookings : _bookings.where((b) => b['status'] == _filters[_filterIndex]).toList();
    if (_search.isNotEmpty) {
      list = list.where((b) =>
          b['ref']!.toString().toLowerCase().contains(_search.toLowerCase()) ||
          b['user']!.toString().toLowerCase().contains(_search.toLowerCase()) ||
          b['hall']!.toString().toLowerCase().contains(_search.toLowerCase())).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('All Bookings'),
          leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18), onPressed: () => Navigator.pop(context)),
        ),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: const InputDecoration(
                hintText: 'Search ref, user, hall...',
                prefixIcon: Icon(Icons.search, size: 18),
                suffixIcon: Icon(Icons.tune, size: 18),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FilterChipRow(chips: _filters, selected: _filterIndex, onSelected: (i) => setState(() => _filterIndex = i)),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Text('${_filtered.length} bookings', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            ]),
          ),
          const SizedBox(height: 6),
          Expanded(child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
                  ? const Center(child: Text('No bookings found',
                      style: TextStyle(color: AppTheme.textSecondary)))
                  : RefreshIndicator(
                      onRefresh: _loadBookings,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) => _buildCard(_filtered[i]),
                      ),
                    )),
        ]),
      );

  Widget _buildCard(Map<String, dynamic> b) {
    final stMap = {
      'success': StatusType.success, 'warning': StatusType.warning,
      'danger': StatusType.danger, 'neutral': StatusType.neutral,
    };
    final st = stMap[b['statusType']] ?? StatusType.info;
    final isPending = b['status'] == 'Pending';
    final isConfirmed = b['status'] == 'Confirmed';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(b['ref']!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            StatusBadge(label: b['status']!, type: st),
          ]),
          const SizedBox(height: 5),
          Row(children: [
            const Icon(Icons.person_outline, size: 14, color: AppTheme.textSecondary),
            const SizedBox(width: 4),
            Text(b['user']!, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            const SizedBox(width: 10),
            const Icon(Icons.meeting_room_outlined, size: 14, color: AppTheme.textSecondary),
            const SizedBox(width: 4),
            Expanded(child: Text(b['hall']!, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary), overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 4),
          Text('📅 ${b['date']}  ·  🕐 ${b['time']}', style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary)),
          const SizedBox(height: 8),
          Row(children: [
            Text(b['price']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.primary)),
            const Spacer(),
          ]),
          const Divider(height: 16),
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () => _showBookingDetail(context, b),
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 34), padding: const EdgeInsets.symmetric(horizontal: 8), textStyle: const TextStyle(fontSize: 12)),
              child: const Text('View'),
            )),
            const SizedBox(width: 6),
            if (isPending) ...[
              Expanded(child: OutlinedButton(
                onPressed: () => _updateStatus(b, 'Confirmed'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 34), padding: const EdgeInsets.symmetric(horizontal: 8), textStyle: const TextStyle(fontSize: 12), foregroundColor: AppTheme.success, side: const BorderSide(color: AppTheme.success)),
                child: const Text('Approve'),
              )),
              const SizedBox(width: 6),
              Expanded(child: OutlinedButton(
                onPressed: () => _updateStatus(b, 'Cancelled'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 34), padding: const EdgeInsets.symmetric(horizontal: 8), textStyle: const TextStyle(fontSize: 12), foregroundColor: AppTheme.danger, side: const BorderSide(color: AppTheme.danger)),
                child: const Text('Reject'),
              )),
            ],
            if (isConfirmed) ...[
              Expanded(child: OutlinedButton(
                onPressed: () => _showEditDialog(context, b),
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 34), padding: const EdgeInsets.symmetric(horizontal: 8), textStyle: const TextStyle(fontSize: 12)),
                child: const Text('Edit'),
              )),
              const SizedBox(width: 6),
              Expanded(child: OutlinedButton(
                onPressed: () => _updateStatus(b, 'Cancelled'),
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 34), padding: const EdgeInsets.symmetric(horizontal: 8), textStyle: const TextStyle(fontSize: 12), foregroundColor: AppTheme.danger, side: const BorderSide(color: AppTheme.danger)),
                child: const Text('Cancel'),
              )),
            ],
          ]),
        ]),
      ),
    );
  }

  Future<void> _updateStatus(Map<String, dynamic> b, String newStatus) async {
    final ok = await _dbService.updateBookingStatus(b['id'].toString(), newStatus);
    if (!mounted) return;
    if (ok) await _loadBookings();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? 'Booking ${b['ref']} updated to $newStatus'
            : 'Failed to update booking'),
        backgroundColor: ok ? AppTheme.success : AppTheme.danger));
  }

  void _showBookingDetail(BuildContext context, Map<String, dynamic> b) => showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(b['ref']!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              StatusBadge(label: b['status']!, type: StatusType.success),
            ]),
            const SizedBox(height: 16),
            _detailRow('User', b['user']!),
            _detailRow('Hall', b['hall']!),
            _detailRow('Date', b['date']!),
            _detailRow('Time', b['time']!),
            _detailRow('Total', b['price']!),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ]),
        ),
      );

  Widget _detailRow(String l, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          SizedBox(width: 80, child: Text(l, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary))),
          Expanded(child: Text(v, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
        ]),
      );

  void _showEditDialog(BuildContext context, Map<String, dynamic> b) => showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Edit Booking', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(initialValue: b['date'], decoration: const InputDecoration(labelText: 'Date')),
            const SizedBox(height: 10),
            TextFormField(initialValue: b['time'], decoration: const InputDecoration(labelText: 'Time slot')),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking updated'), backgroundColor: AppTheme.success));
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
}

