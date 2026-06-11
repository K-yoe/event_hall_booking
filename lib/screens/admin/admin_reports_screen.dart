import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../services/app_events.dart';
import '../../services/db_service.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});
  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  String _period = 'This Month';
  final _periods = ['This Week', 'This Month', 'This Quarter', 'This Year'];

  final _db = DbService();
  double _revenue = 0;
  int _totalB = 0, _confirmed = 0, _pending = 0, _cancelled = 0, _completed = 0;
  int _activeHalls = 0;
  int _paidCount = 0;
  double _avgRating = 0;

  // DB-derived analytics (see DbService.getAnalytics).
  List<Map<String, dynamic>> _revenueByMethod = [];
  List<Map<String, dynamic>> _revenueByType = [];
  List<Map<String, dynamic>> _topCustomers = [];
  List<Map<String, dynamic>> _hallPerformance = [];
  List<Map<String, dynamic>> _monthlyRevenue = [];
  List<int> _bookingsByDay = List<int>.filled(7, 0);

  static const _avatarBg = [
    Color(0xFFE6F1FB), Color(0xFFFAEEDA), Color(0xFFF1EFE8),
    Color(0xFFFBEAF0), Color(0xFFEAF3DE),
  ];
  static const _avatarFg = [
    Color(0xFF0C447C), Color(0xFF633806), Color(0xFF444441),
    Color(0xFF72243E), Color(0xFF27500A),
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _loadReports();
    AppEvents.dataVersion.addListener(_loadReports);
  }

  Future<void> _loadReports() async {
    final stats = await _db.getStats();
    final bookings = await _db.getAllBookings();
    final halls = await _db.getHalls();
    final payments = await _db.getPaymentRecords();
    final analytics = await _db.getAnalytics();
    if (!mounted) return;
    int countBy(String s) => bookings.where((b) => b['status'] == s).length;
    final ratings = halls
        .map((h) => (h['rating'] as num?)?.toDouble() ?? 0.0)
        .where((r) => r > 0)
        .toList();
    setState(() {
      _revenue = (stats['revenue'] as num).toDouble();
      _totalB = bookings.length;
      _confirmed = countBy('Confirmed');
      _pending = countBy('Pending');
      _cancelled = countBy('Cancelled');
      _completed = countBy('Completed');
      _activeHalls = halls.where((h) => h['isActive'] == true).length;
      _paidCount = payments.where((p) => p['status'] == 'Paid').length;
      _avgRating = ratings.isEmpty
          ? 0
          : ratings.reduce((a, b) => a + b) / ratings.length;
      _revenueByMethod = (analytics['revenueByMethod'] as List).cast<Map<String, dynamic>>();
      _revenueByType = (analytics['revenueByType'] as List).cast<Map<String, dynamic>>();
      _topCustomers = (analytics['topCustomers'] as List).cast<Map<String, dynamic>>();
      _hallPerformance = (analytics['hallPerformance'] as List).cast<Map<String, dynamic>>();
      _monthlyRevenue = (analytics['monthlyRevenue'] as List).cast<Map<String, dynamic>>();
      _bookingsByDay = (analytics['bookingsByDay'] as List).cast<int>();
    });
  }

  @override
  void dispose() {
    AppEvents.dataVersion.removeListener(_loadReports);
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppTheme.surface,
        body: NestedScrollView(
          headerSliverBuilder: (_, __) => [
            SliverAppBar(
              pinned: true,
              backgroundColor: AppTheme.adminPrimary,
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Color(0xFFFAEEDA)),
                  onPressed: () => Navigator.pop(context)),
              title: const Text('Reports & Analytics',
                  style: TextStyle(color: Color(0xFFFAEEDA), fontWeight: FontWeight.w700)),
              actions: [
                IconButton(
                  icon: const Icon(Icons.download_outlined, color: Color(0xFFFAC775)),
                  onPressed: () => _showExportSheet(context),
                ),
              ],
              bottom: TabBar(
                controller: _tabs,
                indicatorColor: const Color(0xFFFAC775),
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFFFAC775).withOpacity(0.6),
                labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                tabs: const [
                  Tab(text: 'Revenue'),
                  Tab(text: 'Bookings'),
                  Tab(text: 'Halls'),
                ],
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabs,
            children: [
              _revenueTab(),
              _bookingsTab(),
              _hallsTab(),
            ],
          ),
        ),
      );

  // ── Period Selector ─────────────────────────────────────────────────────────
  Widget _periodSelector() => Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: _periods.map((p) => GestureDetector(
                onTap: () => setState(() => _period = p),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: _period == p ? AppTheme.adminPrimary : Colors.white,
                    border: Border.all(
                        color: _period == p ? AppTheme.adminPrimary : AppTheme.cardBorder),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(p, style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: _period == p ? Colors.white : AppTheme.textSecondary)),
                ),
              )).toList()),
        ),
      );

  // ══════════════════════════════════════════════════════════════════════
  //  REVENUE TAB
  // ══════════════════════════════════════════════════════════════════════
  Widget _revenueTab() => SingleChildScrollView(child: Column(children: [
        _periodSelector(),
        // KPI cards
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: [
            // Big revenue card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppTheme.adminPrimary, Color(0xFF3D1E00)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Total Revenue', style: TextStyle(fontSize: 13, color: Color(0xFFFAC775))),
                const SizedBox(height: 6),
                Text('RM ${_revenue.toStringAsFixed(0)}', style: const TextStyle(
                    fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
                const SizedBox(height: 6),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: AppTheme.successLight, borderRadius: BorderRadius.circular(6)),
                    child: const Text('↑ 14% vs last month',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.success)),
                  ),
                ]),
              ]),
            ),
            const SizedBox(height: 12),
            _revenueByTypeRow(),
          ]),
        ),
        const SizedBox(height: 20),
        // Bar chart
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SectionHeader(title: 'Monthly Revenue'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.cardBorder)),
              child: Column(children: [
                _barChart(),
                const SizedBox(height: 8),
                Text(_monthlyRevenue.isEmpty
                    ? 'No revenue yet'
                    : '${_monthlyRevenue.first['label']} – ${_monthlyRevenue.last['label']}',
                    style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 20),
        // Revenue by method
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SectionHeader(title: 'Revenue by Payment Method'),
            Container(
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.cardBorder)),
              child: _revenueByMethodList(),
            ),
          ]),
        ),
        const SizedBox(height: 24),
      ]));

  Widget _kpiCard(String val, String label, IconData icon, Color bg, Color fg) =>
      Expanded(child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: fg.withOpacity(0.15))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 18, color: fg),
          const SizedBox(height: 6),
          Text(val, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: fg)),
          Text(label, style: TextStyle(fontSize: 10, color: fg.withOpacity(0.7), fontWeight: FontWeight.w500)),
        ]),
      ));

  // Revenue split across hall types (Paid payments) — top 3 shown as cards.
  Widget _revenueByTypeRow() {
    const palette = [
      [AppTheme.primaryLight, AppTheme.primary],
      [AppTheme.successLight, AppTheme.success],
      [Color(0xFFFAEEDA), AppTheme.adminPrimary],
    ];
    const icons = [Icons.meeting_room_outlined, Icons.work_outline, Icons.more_horiz];
    if (_revenueByType.isEmpty) {
      return Row(children: [
        _kpiCard('RM 0', 'No revenue', Icons.meeting_room_outlined,
            AppTheme.primaryLight, AppTheme.primary),
      ]);
    }
    final items = _revenueByType.take(3).toList();
    return Row(children: [
      for (var i = 0; i < items.length; i++) ...[
        if (i > 0) const SizedBox(width: 10),
        _kpiCard('RM ${(items[i]['amount'] as double).toStringAsFixed(0)}',
            items[i]['type'] as String, icons[i],
            palette[i][0], palette[i][1]),
      ],
    ]);
  }

  // Revenue by payment method (Paid payments) as proportional bars.
  Widget _revenueByMethodList() {
    if (_revenueByMethod.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No payments recorded yet',
            style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
      );
    }
    const colors = [
      AppTheme.primary, AppTheme.success, Color(0xFF72243E),
      Color(0xFF27500A), AppTheme.textSecondary,
    ];
    final total = _revenueByMethod.fold<double>(
        0, (sum, m) => sum + (m['amount'] as double));
    return Column(children: [
      for (var i = 0; i < _revenueByMethod.length; i++)
        _methodRow(_revenueByMethod[i]['method'] as String,
            _revenueByMethod[i]['amount'] as double,
            total == 0 ? 1 : total, colors[i % colors.length]),
    ]);
  }

  Widget _barChart() {
    if (_monthlyRevenue.isEmpty) {
      return const SizedBox(
        height: 140,
        child: Center(child: Text('No revenue data',
            style: TextStyle(fontSize: 12, color: AppTheme.textTertiary))),
      );
    }
    final months = _monthlyRevenue.map((m) => m['label'] as String).toList();
    final values = _monthlyRevenue.map((m) => m['amount'] as double).toList();
    final maxVal = values.reduce((a, b) => a > b ? a : b);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(months.length, (i) {
        final h = maxVal == 0 ? 0.0 : (values[i] / maxVal) * 120;
        final isCurrent = i == months.length - 1;
        return Column(mainAxisSize: MainAxisSize.min, children: [
          Text('RM ${(values[i] / 1000).toStringAsFixed(0)}k',
              style: TextStyle(fontSize: 8, color: isCurrent ? AppTheme.adminPrimary : AppTheme.textTertiary,
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.normal)),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
            width: 32, height: h,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: isCurrent
                    ? [AppTheme.adminPrimary, const Color(0xFF3D1E00)]
                    : [AppTheme.primaryLight, AppTheme.primaryLight.withBlue(200)],
              ),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 6),
          Text(months[i], style: TextStyle(fontSize: 10,
              color: isCurrent ? AppTheme.adminPrimary : AppTheme.textSecondary,
              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.normal)),
        ]);
      }),
    );
  }

  Widget _methodRow(String method, double amount, double total, Color color) {
    final pct = (amount / total * 100).round();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(children: [
        Row(children: [
          Expanded(child: Text(method, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
          Text('RM ${amount.toInt()}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          Text('$pct%', style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: amount / total,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  BOOKINGS TAB
  // ══════════════════════════════════════════════════════════════════════
  Widget _bookingsTab() => SingleChildScrollView(child: Column(children: [
        _periodSelector(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: [
            // Summary row
            Row(children: [
              _kpiCard('$_totalB', 'Total', Icons.event_outlined, AppTheme.primaryLight, AppTheme.primary),
              const SizedBox(width: 10),
              _kpiCard('$_confirmed', 'Confirmed', Icons.check_circle_outline, AppTheme.successLight, AppTheme.success),
              const SizedBox(width: 10),
              _kpiCard('$_pending', 'Pending', Icons.pending_outlined, AppTheme.warningLight, AppTheme.warning),
            ]),
            const SizedBox(height: 10),
            Row(children: [
              _kpiCard('$_cancelled', 'Cancelled', Icons.cancel_outlined, AppTheme.dangerLight, AppTheme.danger),
              const SizedBox(width: 10),
              _kpiCard('${_totalB == 0 ? 0 : (_confirmed / _totalB * 100).round()}%', 'Fill Rate',
                  Icons.percent_outlined, AppTheme.primaryLight, AppTheme.primaryDark),
              const SizedBox(width: 10),
              _kpiCard('RM ${_paidCount == 0 ? 0 : (_revenue / _paidCount).round()}', 'Avg Value',
                  Icons.trending_up, const Color(0xFFFAEEDA), AppTheme.adminPrimary),
            ]),
          ]),
        ),
        const SizedBox(height: 20),
        // Bookings by day of week
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SectionHeader(title: 'Bookings by Day of Week'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.cardBorder)),
              child: _dayOfWeekChart(),
            ),
          ]),
        ),
        const SizedBox(height: 20),
        // Status breakdown
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SectionHeader(title: 'Booking Status Breakdown'),
            Container(
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.cardBorder)),
              child: Column(children: [
                _statusRow('Confirmed', _confirmed, _totalB == 0 ? 1 : _totalB, AppTheme.success),
                _statusRow('Pending',   _pending,   _totalB == 0 ? 1 : _totalB, AppTheme.warning),
                _statusRow('Completed', _completed, _totalB == 0 ? 1 : _totalB, AppTheme.textSecondary),
                _statusRow('Cancelled', _cancelled, _totalB == 0 ? 1 : _totalB, AppTheme.danger),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 20),
        // Top users
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SectionHeader(title: 'Top Customers'),
            Container(
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.cardBorder)),
              child: _topCustomers.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No customers yet',
                          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                    )
                  : Column(children: [
                      for (var i = 0; i < _topCustomers.take(5).length; i++)
                        _TopUserRow(
                          _topCustomers[i]['name'] as String,
                          _topCustomers[i]['bookings'] as int,
                          'RM ${(_topCustomers[i]['spent'] as double).toStringAsFixed(0)}',
                          _topCustomers[i]['initials'] as String,
                          _avatarBg[i % _avatarBg.length],
                          _avatarFg[i % _avatarFg.length],
                        ),
                    ]),
            ),
          ]),
        ),
        const SizedBox(height: 24),
      ]));

  Widget _dayOfWeekChart() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final counts = _bookingsByDay;
    final maxRaw = counts.reduce((a, b) => a > b ? a : b);
    final max = maxRaw == 0 ? 1 : maxRaw;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (i) {
        final h = (counts[i] / max) * 100.0;
        final isWeekend = i >= 5;
        return Column(mainAxisSize: MainAxisSize.min, children: [
          Text('${counts[i]}',
              style: const TextStyle(fontSize: 9, color: AppTheme.textTertiary)),
          const SizedBox(height: 4),
          AnimatedContainer(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOut,
            width: 30, height: h,
            decoration: BoxDecoration(
              color: isWeekend ? AppTheme.warningLight : AppTheme.primaryLight,
              border: Border.all(
                  color: isWeekend ? AppTheme.warning : AppTheme.primary, width: 1.5),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 5),
          Text(days[i], style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w500,
              color: isWeekend ? AppTheme.warning : AppTheme.textSecondary)),
        ]);
      }),
    );
  }

  Widget _statusRow(String label, int count, int total, Color color) {
    final pct = (count / total * 100).round();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(children: [
        Row(children: [
          Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
          Text('$count bookings', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          Text('$pct%', style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: count / total,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  //  HALLS TAB
  // ══════════════════════════════════════════════════════════════════════
  Widget _hallsTab() => SingleChildScrollView(child: Column(children: [
        _periodSelector(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            _kpiCard('$_activeHalls', 'Active Halls', Icons.meeting_room_outlined, AppTheme.primaryLight, AppTheme.primary),
            const SizedBox(width: 10),
            _kpiCard('${_totalB == 0 ? 0 : (_confirmed / _totalB * 100).round()}%', 'Confirmed Rate', Icons.people_outline, AppTheme.successLight, AppTheme.success),
            const SizedBox(width: 10),
            _kpiCard(_avgRating.toStringAsFixed(1), 'Avg Rating', Icons.star_outline, const Color(0xFFFFF9EC), const Color(0xFFB45309)),
          ]),
        ),
        const SizedBox(height: 20),
        // Hall performance
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SectionHeader(title: 'Hall Performance'),
            Container(
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.cardBorder)),
              child: _hallPerformance.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No hall data yet',
                          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                    )
                  : Column(children: [
                      for (final h in _hallPerformance)
                        _hallPerfRow(
                          h['name'] as String,
                          h['bookings'] as int,
                          h['occupancy'] as int,
                          h['rating'] as double,
                          'RM ${(h['revenue'] as double).toStringAsFixed(0)}',
                        ),
                    ]),
            ),
          ]),
        ),
        const SizedBox(height: 20),
        // Occupancy heatmap
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SectionHeader(title: 'Occupancy by Time Slot'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.cardBorder)),
              child: _occupancyHeatmap(),
            ),
          ]),
        ),
        const SizedBox(height: 24),
      ]));

  Widget _hallPerfRow(String name, int bookings, int occ, double rating, String revenue) =>
      Container(
        padding: const EdgeInsets.all(14),
        decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppTheme.cardBorder, width: 0.5))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
            Text(revenue, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.adminPrimary)),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            _miniStat('$bookings bookings', Icons.event_outlined),
            const SizedBox(width: 12),
            _miniStat('$occ% occupancy', Icons.people_outline),
            const SizedBox(width: 12),
            _miniStat('⭐ $rating', null),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: occ / 100,
              backgroundColor: AppTheme.primaryLight,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
              minHeight: 5,
            ),
          ),
        ]),
      );

  Widget _miniStat(String label, IconData? icon) => Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 12, color: AppTheme.textTertiary), const SizedBox(width: 3)],
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
      ]);

  Widget _occupancyHeatmap() {
    final slots = ['8–10', '10–12', '12–14', '14–16', '16–18', '18–20'];
    final days  = ['Mon', 'Wed', 'Fri', 'Sat'];
    // occupancy % values
    final data = [
      [40, 80, 30, 90, 50, 20],
      [60, 95, 45, 85, 70, 35],
      [75, 90, 55, 100, 80, 60],
      [50, 70, 40, 65, 55, 85],
    ];
    return Column(children: [
      Row(children: [
        const SizedBox(width: 36),
        ...slots.map((s) => Expanded(child: Text(s,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 8, color: AppTheme.textTertiary)))),
      ]),
      const SizedBox(height: 6),
      ...List.generate(days.length, (di) => Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(children: [
              SizedBox(width: 36, child: Text(days[di],
                  style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary))),
              ...List.generate(slots.length, (si) {
                final val = data[di][si];
                final opacity = val / 100;
                return Expanded(child: Container(
                  height: 26, margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: AppTheme.adminPrimary.withOpacity(opacity),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(child: Text('$val%',
                      style: TextStyle(fontSize: 7, fontWeight: FontWeight.w700,
                          color: val > 50 ? Colors.white : AppTheme.textSecondary))),
                ));
              }),
            ]),
          )),
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        Container(width: 12, height: 12, color: AppTheme.adminPrimary.withOpacity(0.15)),
        const SizedBox(width: 4),
        const Text('Low', style: TextStyle(fontSize: 10, color: AppTheme.textTertiary)),
        const SizedBox(width: 12),
        Container(width: 12, height: 12, color: AppTheme.adminPrimary),
        const SizedBox(width: 4),
        const Text('High', style: TextStyle(fontSize: 10, color: AppTheme.textTertiary)),
      ]),
    ]);
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
            const Text('Export Report', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            ListTile(
              onTap: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PDF report exported!'))); },
              leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFFFAEEDA), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.picture_as_pdf_outlined, color: AppTheme.adminPrimary)),
              title: const Text('Export PDF Report', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Full analytics report'),
              trailing: const Icon(Icons.chevron_right),
            ),
            ListTile(
              onTap: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('CSV exported!'))); },
              leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: AppTheme.successLight, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.table_chart_outlined, color: AppTheme.success)),
              title: const Text('Export CSV Data', style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: const Text('Raw data spreadsheet'),
              trailing: const Icon(Icons.chevron_right),
            ),
          ]),
        ),
      );
}

// ── Top User Row widget ───────────────────────────────────────────────────────
class _TopUserRow extends StatelessWidget {
  final String name, revenue, initials;
  final int bookings;
  final Color avBg, avFg;
  const _TopUserRow(this.name, this.bookings, this.revenue, this.initials, this.avBg, this.avFg);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppTheme.cardBorder, width: 0.5))),
        child: Row(children: [
          CircleAvatar(radius: 18, backgroundColor: avBg,
              child: Text(initials, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: avFg))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            Text('$bookings bookings', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
          ])),
          Text(revenue, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.adminPrimary)),
        ]),
      );
}
