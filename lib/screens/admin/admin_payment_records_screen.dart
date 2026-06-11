import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../services/db_service.dart';

class AdminPaymentRecordsScreen extends StatefulWidget {
  const AdminPaymentRecordsScreen({super.key});
  @override
  State<AdminPaymentRecordsScreen> createState() => _AdminPaymentRecordsScreenState();
}

class _AdminPaymentRecordsScreenState extends State<AdminPaymentRecordsScreen> {
  int _filterIndex = 0;
  String _search = '';
  String _sortBy = 'Newest';
  bool _isLoading = false;
  final _filters = ['All', 'Paid', 'Pending', 'Failed', 'Refunded'];
  final _dbService = DbService();

  List<Map<String, dynamic>> _payments = [];

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() => _isLoading = true);
    final rows = await _dbService.getPaymentRecords();
    if (!mounted) return;
    setState(() {
      _payments = rows.map(_normalize).toList();
      _isLoading = false;
    });
  }

  Map<String, dynamic> _normalize(Map<String, dynamic> p) {
    final amount = (p['amount'] is num) ? (p['amount'] as num).toDouble() : 0.0;
    return {
      'id': (p['id'] ?? '').toString(),
      'txn': p['txn'] ?? '',
      'user': p['userName'] ?? '-',
      'hall': p['hallName'] ?? '-',
      'booking': p['bookingRef'] ?? '-',
      'amount': amount,
      'method': p['method'] ?? '-',
      'status': p['status'] ?? 'Pending',
      'date': p['date'] ?? '-',
    };
  }

  List<Map<String, dynamic>> get _filtered {
    var list = List<Map<String, dynamic>>.from(_payments);
    if (_filterIndex > 0) {
      list = list.where((p) => p['status'] == _filters[_filterIndex]).toList();
    }
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((p) =>
          p['txn']!.toString().toLowerCase().contains(q) ||
          p['user']!.toString().toLowerCase().contains(q) ||
          p['hall']!.toString().toLowerCase().contains(q)).toList();
    }
    return list;
  }

  // Summary stats
  double get _totalCollected => _payments
      .where((p) => p['status'] == 'Paid')
      .fold(0.0, (s, p) => s + (p['amount'] as double));
  int get _paidCount    => _payments.where((p) => p['status'] == 'Paid').length;
  int get _pendingCount => _payments.where((p) => p['status'] == 'Pending').length;
  int get _failedCount  => _payments.where((p) => p['status'] == 'Failed').length;
  int get _refundCount  => _payments.where((p) => p['status'] == 'Refunded').length;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppTheme.surface,
        appBar: AppBar(
          backgroundColor: AppTheme.adminPrimary,
          foregroundColor: const Color(0xFFFAEEDA),
          surfaceTintColor: Colors.transparent,
          title: const Text('Payment Records',
              style: TextStyle(color: Color(0xFFFAEEDA), fontWeight: FontWeight.w700)),
          leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFFFAEEDA)),
              onPressed: () => Navigator.pop(context)),
          actions: [
            IconButton(
              icon: const Icon(Icons.download_outlined, color: Color(0xFFFAC775)),
              onPressed: () => _showExportSheet(context),
              tooltip: 'Export',
            ),
          ],
        ),
        body: Column(children: [
          // Summary banner
          _summaryBanner(),
          // Search + filter
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: AppSearchBar(
              hint: 'Search txn, user, hall...',
              onChanged: (v) => setState(() => _search = v),
              onFilter: () => _showSortSheet(context),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FilterChipRow(
                chips: _filters,
                selected: _filterIndex,
                onSelected: (i) => setState(() => _filterIndex = i)),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              Text('${_filtered.length} records',
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _showSortSheet(context),
                icon: const Icon(Icons.sort, size: 14),
                label: Text(_sortBy, style: const TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                    foregroundColor: AppTheme.adminPrimary,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0)),
              ),
            ]),
          ),
          // List
          Expanded(child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
                  ? const EmptyState(
                      title: 'No records found',
                      subtitle: 'Try a different filter or search',
                      icon: Icons.receipt_long_outlined)
                  : RefreshIndicator(
                      onRefresh: _loadPayments,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) => _paymentCard(_filtered[i]),
                      ),
                    )),
        ]),
      );

  // ── Summary Banner ─────────────────────────────────────────────────────────
  Widget _summaryBanner() => Container(
        color: AppTheme.adminPrimary,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Total collected', style: TextStyle(fontSize: 12, color: Color(0xFFFAC775))),
              Text('RM ${_totalCollected.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
            ]),
            const Spacer(),
            const Icon(Icons.account_balance_wallet_outlined, size: 40, color: Color(0xFFFAC775)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            _pill('$_paidCount Paid', AppTheme.success, AppTheme.successLight),
            const SizedBox(width: 8),
            _pill('$_pendingCount Pending', AppTheme.warning, AppTheme.warningLight),
            const SizedBox(width: 8),
            _pill('$_failedCount Failed', AppTheme.danger, AppTheme.dangerLight),
            const SizedBox(width: 8),
            _pill('$_refundCount Refunded', AppTheme.primary, AppTheme.primaryLight),
          ]),
        ]),
      );

  Widget _pill(String label, Color fg, Color bg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
      );

  // ── Payment Card ───────────────────────────────────────────────────────────
  Widget _paymentCard(Map<String, dynamic> p) {
    final status = p['status'] as String;
    final st = switch (status) {
      'Paid'     => StatusType.success,
      'Pending'  => StatusType.warning,
      'Failed'   => StatusType.danger,
      'Refunded' => StatusType.info,
      _          => StatusType.neutral,
    };
    final amount = p['amount'] as double;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header row
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(child: Text(p['txn']!,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis)),
            StatusBadge(label: status, type: st),
          ]),
          const SizedBox(height: 6),
          // User + Hall
          Row(children: [
            const Icon(Icons.person_outline, size: 13, color: AppTheme.textSecondary),
            const SizedBox(width: 4),
            Text(p['user']!, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            const SizedBox(width: 12),
            const Icon(Icons.meeting_room_outlined, size: 13, color: AppTheme.textSecondary),
            const SizedBox(width: 4),
            Expanded(child: Text(p['hall']!,
                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 3),
          Row(children: [
            const Icon(Icons.credit_card_outlined, size: 13, color: AppTheme.textTertiary),
            const SizedBox(width: 4),
            Text(p['method']!, style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary)),
            const SizedBox(width: 12),
            const Icon(Icons.access_time, size: 13, color: AppTheme.textTertiary),
            const SizedBox(width: 4),
            Text(p['date']!, style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary)),
          ]),
          const Divider(height: 14),
          Row(children: [
            Text('RM ${amount.toStringAsFixed(2)}',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800,
                    color: status == 'Failed'
                        ? AppTheme.danger
                        : status == 'Refunded'
                            ? AppTheme.primary
                            : AppTheme.adminPrimary)),
            const Spacer(),
            // Admin actions
            if (status == 'Pending')
              _actionBtn('Approve', Icons.check_circle_outline, AppTheme.success, AppTheme.success,
                  () => _setStatus(p, 'Paid')),
            if (status == 'Pending') const SizedBox(width: 6),
            if (status == 'Failed')
              _actionBtn('Retry', Icons.refresh, AppTheme.primary, AppTheme.primary, () {}),
            if (status == 'Paid')
              _actionBtn('Refund', Icons.undo, AppTheme.warning, AppTheme.warning,
                  () => _confirmRefund(p)),
            const SizedBox(width: 6),
            _actionBtn('View', Icons.visibility_outlined, AppTheme.textSecondary, AppTheme.cardBorder,
                () => _showDetail(p)),
          ]),
        ]),
      ),
    );
  }

  Widget _actionBtn(String label, IconData icon, Color fg, Color border, VoidCallback onTap) =>
      OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 13, color: fg),
        label: Text(label, style: TextStyle(fontSize: 11, color: fg)),
        style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 32),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            side: BorderSide(color: border)),
      );

  Future<void> _setStatus(Map<String, dynamic> p, String s) async {
    final ok = await _dbService.updatePaymentStatus(p['id'].toString(), s);
    if (!mounted) return;
    if (ok) await _loadPayments();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? '${p['txn']} updated to $s' : 'Failed to update payment'),
        backgroundColor: ok ? AppTheme.success : AppTheme.danger));
  }

  void _confirmRefund(Map<String, dynamic> p) => showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Issue refund?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          content: Text('Refund RM ${(p['amount'] as double).toStringAsFixed(2)} to ${p['user']}?',
              style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _setStatus(p, 'Refunded');
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warning),
              child: const Text('Issue Refund'),
            ),
          ],
        ),
      );

  void _showDetail(Map<String, dynamic> p) => showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: AppTheme.cardBorder, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Payment Detail', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              StatusBadge(label: p['status']!, type: _statusTypeFromString(p['status']!)),
            ]),
            const Divider(height: 20),
            _dRow('Transaction', p['txn']!),
            _dRow('Booking ref', p['booking']!),
            _dRow('User', p['user']!),
            _dRow('Hall', p['hall']!),
            _dRow('Method', p['method']!),
            _dRow('Date', p['date']!),
            const Divider(height: 16),
            _dRow('Amount', 'RM ${(p['amount'] as double).toStringAsFixed(2)}', bold: true),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download_outlined, size: 16),
                label: const Text('Download'),
              )),
              const SizedBox(width: 10),
              Expanded(child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.adminPrimary),
                child: const Text('Close'),
              )),
            ]),
          ]),
        ),
      );

  StatusType _statusTypeFromString(String s) => switch (s) {
    'Paid'     => StatusType.success,
    'Pending'  => StatusType.warning,
    'Failed'   => StatusType.danger,
    'Refunded' => StatusType.info,
    _          => StatusType.neutral,
  };

  Widget _dRow(String l, String v, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          SizedBox(width: 100, child: Text(l,
              style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary))),
          Expanded(child: Text(v, style: TextStyle(fontSize: 13,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: bold ? AppTheme.adminPrimary : AppTheme.textPrimary))),
        ]),
      );

  void _showSortSheet(BuildContext context) {
    final opts = ['Newest', 'Oldest', 'Amount: High to Low', 'Amount: Low to High'];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppTheme.cardBorder, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          const Text('Sort by', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          ...opts.map((o) => GestureDetector(
                onTap: () { setState(() => _sortBy = o); Navigator.pop(context); },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(
                    color: _sortBy == o ? const Color(0xFFFAEEDA) : AppTheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: _sortBy == o ? AppTheme.adminPrimary : AppTheme.cardBorder,
                        width: _sortBy == o ? 1.5 : 0.5),
                  ),
                  child: Row(children: [
                    Icon(_sortBy == o ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                        size: 18, color: _sortBy == o ? AppTheme.adminPrimary : AppTheme.textTertiary),
                    const SizedBox(width: 10),
                    Text(o, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
                        color: _sortBy == o ? AppTheme.adminPrimary : AppTheme.textPrimary)),
                  ]),
                ),
              )),
        ]),
      ),
    );
  }

  void _showExportSheet(BuildContext context) => showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: AppTheme.cardBorder, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Text('Export Records', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            _exportOption(Icons.table_chart_outlined, 'Export as CSV', 'Spreadsheet format', () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CSV exported!')));
            }),
            _exportOption(Icons.picture_as_pdf_outlined, 'Export as PDF', 'Printable report', () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF exported!')));
            }),
            _exportOption(Icons.bar_chart_outlined, 'View Full Report', 'Charts & analytics', () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/admin/reports');
            }),
          ]),
        ),
      );

  Widget _exportOption(IconData icon, String title, String subtitle, VoidCallback onTap) =>
      ListTile(
        onTap: onTap,
        leading: Container(width: 40, height: 40,
            decoration: BoxDecoration(color: const Color(0xFFFAEEDA), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, size: 20, color: AppTheme.adminPrimary)),
        title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
        trailing: const Icon(Icons.chevron_right, size: 18, color: AppTheme.textTertiary),
      );
}
