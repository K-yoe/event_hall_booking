import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../services/app_events.dart';
import '../../services/db_service.dart';
import '../../services/session_service.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});
  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  int _filterIndex = 0;
  bool _isLoading = false;
  final _filters = ['All', 'Paid', 'Refunded', 'Failed'];
  final _dbService = DbService();

  List<Map<String, dynamic>> _txns = [];

  @override
  void initState() {
    super.initState();
    _loadPayments();
    AppEvents.dataVersion.addListener(_loadPayments);
  }

  @override
  void dispose() {
    AppEvents.dataVersion.removeListener(_loadPayments);
    super.dispose();
  }

  Future<void> _loadPayments() async {
    setState(() => _isLoading = true);
    final rows = await _dbService.getPaymentRecords();
    if (!mounted) return;
    // Only show the signed-in user's own transactions, so this stays in sync
    // with the profile's "Total Spent" and the user's bookings.
    final email = SessionService.instance.email.toLowerCase();
    final mine = email.isEmpty
        ? rows
        : rows.where((p) =>
            (p['userEmail'] as String?)?.toLowerCase() == email).toList();
    setState(() {
      _txns = mine.map(_normalize).toList();
      _isLoading = false;
    });
  }

  Map<String, dynamic> _normalize(Map<String, dynamic> p) {
    final status = (p['status'] ?? 'Paid').toString();
    const statusTypes = {
      'Paid': 'success', 'Refunded': 'success', 'Failed': 'danger', 'Pending': 'warning',
    };
    final amount = (p['amount'] is num) ? (p['amount'] as num).toDouble() : 0.0;
    return {
      'ref': p['txn'] ?? '',
      'hall': p['hallName'] ?? '-',
      'date': p['date'] ?? '-',
      'method': p['method'] ?? '-',
      'amount': 'RM ${amount.toStringAsFixed(0)}',
      'status': status,
      'statusType': statusTypes[status] ?? 'neutral',
    };
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filterIndex == 0) return _txns;
    final label = _filters[_filterIndex];
    return _txns.where((t) => t['status'] == label).toList();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Payment History')),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: FilterChipRow(chips: _filters, selected: _filterIndex,
                onSelected: (i) => setState(() => _filterIndex = i)),
          ),
          const SizedBox(height: 4),
          Expanded(child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
                  ? const Center(child: Text('No transactions found',
                      style: TextStyle(color: AppTheme.textSecondary)))
                  : RefreshIndicator(
                      onRefresh: _loadPayments,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) => _buildCard(_filtered[i]),
                      ),
                    )),
        ]),
      );

  Widget _buildCard(Map<String, dynamic> t) {
    final stMap = {'success': StatusType.success, 'danger': StatusType.danger};
    final st = stMap[t['statusType']] ?? StatusType.neutral;
    final isFailed = t['status'] == 'Failed';
    final isRefunded = t['status'] == 'Refunded';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(t['ref']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            StatusBadge(label: t['status']!, type: st),
          ]),
          const SizedBox(height: 5),
          Text(t['hall']!, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          Text('${t['method']}  ·  ${t['date']}', style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary)),
          if (isRefunded && t['refundDate'] != null)
            Text(t['refundDate']!, style: const TextStyle(fontSize: 12, color: AppTheme.success)),
          const SizedBox(height: 8),
          Row(children: [
            Text(t['amount']!,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                    color: isFailed ? AppTheme.danger : isRefunded ? AppTheme.success : AppTheme.primary)),
            const Spacer(),
            if (!isFailed)
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.receipt_outlined, size: 14),
                label: const Text('Receipt', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(foregroundColor: AppTheme.primary, padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
              ),
            if (isFailed)
              TextButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/payment/method'),
                icon: const Icon(Icons.refresh, size: 14, color: AppTheme.danger),
                label: const Text('Retry', style: TextStyle(fontSize: 12, color: AppTheme.danger)),
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
              ),
          ]),
        ]),
      ),
    );
  }
}
