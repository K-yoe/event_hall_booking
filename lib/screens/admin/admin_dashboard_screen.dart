import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../services/app_events.dart';
import '../../services/database_helper.dart';
import '../../services/db_service.dart';
import '../../services/session_service.dart';
import 'admin_profile_screen.dart';
import 'admin_payment_records_screen.dart';
import 'admin_reports_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _db = DbService();
  Map<String, dynamic> _stats = {'halls': 0, 'users': 0, 'bookings': 0, 'revenue': 0.0};
  int _todaysBookings = 0;
  List<Map<String, dynamic>> _recent = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
    AppEvents.dataVersion.addListener(_loadStats);
  }

  @override
  void dispose() {
    AppEvents.dataVersion.removeListener(_loadStats);
    super.dispose();
  }

  Future<void> _loadStats() async {
    final stats = await _db.getStats();
    final bookings = await _db.getAllBookings();
    if (!mounted) return;
    setState(() {
      _stats = stats;
      _todaysBookings = bookings.where((b) => b['upcoming'] == true).length;
      _recent = bookings.take(4).toList();
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppTheme.surface,
        body: Column(children: [
          _header(context),
          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _statsRow(),
              const SizedBox(height: 14),
              // Revenue card — tapping navigates to Reports
              _revenueCard(context),
              const SizedBox(height: 20),
              const SectionHeader(title: 'Quick Actions'),
              _quickActions(context),
              const SizedBox(height: 20),
              SectionHeader(
                title: 'Recent Bookings',
                trailing: TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/admin/all-bookings'),
                  child: const Text('View all', style: TextStyle(fontSize: 13)),
                ),
              ),
              _recentTable(context),
              const SizedBox(height: 20),
            ]),
          )),
        ]),
      );

  // ── Seed Database (push all demo data to Firestore) ───────────────────────
  Future<void> _seedDatabase(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final counts = await DatabaseHelper.instance.reseed();
      await _loadStats();
      if (context.mounted) Navigator.pop(context); // close spinner
      messenger.showSnackBar(SnackBar(
        backgroundColor: AppTheme.success,
        content: Text('Database seeded: ${counts['halls']} halls, '
            '${counts['bookings']} bookings, ${counts['payments']} payments, '
            '${counts['users']} users'),
      ));
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      messenger.showSnackBar(SnackBar(
        backgroundColor: AppTheme.danger,
        content: Text('Seeding failed: $e'),
      ));
    }
  }

  // ── Export the database file to a browsable folder ────────────────────────
  Future<void> _exportDatabase(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final path = await DatabaseHelper.instance.exportToAccessibleFolder();
      messenger.showSnackBar(SnackBar(
        backgroundColor: AppTheme.success,
        duration: const Duration(seconds: 8),
        content: Text('Database copied to:\n$path'),
      ));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        backgroundColor: AppTheme.danger,
        content: Text('Export failed: $e'),
      ));
    }
  }

  // ── Header (with profile button) ──────────────────────────────────────────
  Widget _header(BuildContext context) => Container(
        color: AppTheme.adminPrimary,
        padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16, right: 16, bottom: 16),
        child: Row(children: [
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Admin Panel',
                style: TextStyle(fontSize: 12, color: Color(0xFFFAC775), fontWeight: FontWeight.w600)),
            Text('EventSpace',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFFFAEEDA))),
          ]),
          const Spacer(),
          // Red dot notification
          Container(width: 10, height: 10,
              decoration: const BoxDecoration(color: Color(0xFFE24B4A), shape: BoxShape.circle),
              margin: const EdgeInsets.only(right: 10)),
          // Profile avatar — tappable
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => const AdminProfileScreen())),
            child: CircleAvatar(
              radius: 20, backgroundColor: const Color(0xFFFAC775),
              child: const Text('AD',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.adminPrimary)),
            ),
          ),
          const SizedBox(width: 6),
          // More menu
          PopupMenuButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFFFAEEDA)),
            itemBuilder: (_) => [
              PopupMenuItem(
                child: const ListTile(
                  leading: Icon(Icons.person_outline),
                  title: Text('My Profile'), contentPadding: EdgeInsets.zero,
                ),
                onTap: () => Future(() => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AdminProfileScreen()))),
              ),
              PopupMenuItem(
                child: const ListTile(
                  leading: Icon(Icons.bar_chart_outlined),
                  title: Text('Reports'), contentPadding: EdgeInsets.zero,
                ),
                onTap: () => Future(() => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const AdminReportsScreen()))),
              ),
              PopupMenuItem(
                child: const ListTile(
                  leading: Icon(Icons.cloud_upload_outlined, color: AppTheme.primary),
                  title: Text('Seed Database'), contentPadding: EdgeInsets.zero,
                ),
                onTap: () => Future(() => _seedDatabase(context)),
              ),
              PopupMenuItem(
                child: const ListTile(
                  leading: Icon(Icons.folder_outlined, color: AppTheme.primary),
                  title: Text('Export DB File'), contentPadding: EdgeInsets.zero,
                ),
                onTap: () => Future(() => _exportDatabase(context)),
              ),
              PopupMenuItem(
                child: const ListTile(
                  leading: Icon(Icons.logout, color: AppTheme.danger),
                  title: Text('Logout', style: TextStyle(color: AppTheme.danger)),
                  contentPadding: EdgeInsets.zero,
                ),
                onTap: () => Future(() async {
                  await SessionService.instance.logout();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
                  }
                }),
              ),
            ],
          ),
        ]),
      );

  // ── Stats Row ──────────────────────────────────────────────────────────────
  Widget _statsRow() => Row(children: [
        _stat('${_stats['halls']}', 'Total Halls', Icons.meeting_room_outlined, AppTheme.primaryLight, AppTheme.primary),
        const SizedBox(width: 10),
        _stat('${_stats['users']}', 'Users', Icons.people_outline, AppTheme.successLight, AppTheme.success),
        const SizedBox(width: 10),
        _stat('$_todaysBookings', 'Upcoming', Icons.event_outlined, AppTheme.warningLight, AppTheme.warning),
      ]);

  Widget _stat(String n, String label, IconData icon, Color bg, Color fg) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, size: 20, color: fg),
            const SizedBox(height: 6),
            Text(n, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: fg)),
            Text(label,
                style: TextStyle(fontSize: 10, color: fg.withOpacity(0.8), fontWeight: FontWeight.w500)),
          ]),
        ),
      );

  // ── Revenue Card — taps to Reports ────────────────────────────────────────
  Widget _revenueCard(BuildContext context) => GestureDetector(
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AdminReportsScreen())),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryDark]),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Total Revenue (Paid)',
                  style: TextStyle(fontSize: 13, color: Color(0xFFB5D4F4))),
              const SizedBox(height: 4),
              Text('RM ${(_stats['revenue'] as num).toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white)),
              const SizedBox(height: 6),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                      color: AppTheme.successLight,
                      borderRadius: BorderRadius.circular(6)),
                  child: const Text('↑ 14% vs last month',
                      style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700,
                          color: AppTheme.success)),
                ),
                const SizedBox(width: 8),
                // "View report" hint
                const Text('View report →',
                    style: TextStyle(fontSize: 11, color: Color(0xFFB5D4F4),
                        fontWeight: FontWeight.w500)),
              ]),
            ]),
            const Spacer(),
            const Icon(Icons.bar_chart_rounded, size: 56, color: Color(0xFF4A8FD4)),
          ]),
        ),
      );

  // ── Quick Actions Grid ─────────────────────────────────────────────────────
  Widget _quickActions(BuildContext context) => GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.05,
        children: [
          _action(Icons.meeting_room_outlined, 'Manage\nHalls',
              () => Navigator.pushNamed(context, '/admin/manage-halls')),
          _action(Icons.people_outline, 'Manage\nUsers',
              () => Navigator.pushNamed(context, '/admin/manage-users')),
          _action(Icons.receipt_long_outlined, 'All\nBookings',
              () => Navigator.pushNamed(context, '/admin/all-bookings')),
          _action(Icons.add_circle_outline, 'Add\nHall',
              () => Navigator.pushNamed(context, '/admin/add-hall')),
          _action(Icons.credit_card_outlined, 'Payment\nRecords',
              () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AdminPaymentRecordsScreen()))),
          _action(Icons.bar_chart_outlined, 'Reports',
              () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AdminReportsScreen()))),
        ],
      );

  Widget _action(IconData icon, String label, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.cardBorder),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 28, color: AppTheme.adminPrimary),
            const SizedBox(height: 6),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, height: 1.3)),
          ]),
        ),
      );

  // ── Recent Bookings Table ──────────────────────────────────────────────────
  Widget _recentTable(BuildContext context) => Container(
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.cardBorder)),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12))),
            child: const Row(children: [
              Expanded(flex: 2, child: Text('User',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textTertiary))),
              Expanded(flex: 2, child: Text('Hall',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textTertiary))),
              Expanded(child: Text('Status',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textTertiary))),
              Expanded(child: SizedBox()),
            ]),
          ),
          if (_recent.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No bookings yet',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            )
          else
            ..._recent.map((b) => _tableRow((
                  (b['userName'] ?? '-').toString(),
                  (b['hallName'] ?? '-').toString(),
                  (b['status'] ?? 'Pending').toString(),
                  _statusType((b['status'] ?? 'Pending').toString()),
                ), context)),
        ]),
      );

  static StatusType _statusType(String status) => switch (status) {
        'Confirmed' => StatusType.success,
        'Pending' => StatusType.warning,
        'Cancelled' => StatusType.danger,
        'Completed' => StatusType.neutral,
        _ => StatusType.info,
      };

  static Widget _tableRow(
      (String, String, String, StatusType) r, BuildContext context) =>
      InkWell(
        onTap: () => Navigator.pushNamed(context, '/admin/all-bookings'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppTheme.cardBorder))),
          child: Row(children: [
            Expanded(flex: 2, child: Text(r.$1, style: const TextStyle(fontSize: 13))),
            Expanded(flex: 2, child: Text(r.$2, style: const TextStyle(fontSize: 13))),
            Expanded(child: StatusBadge(label: r.$3, type: r.$4)),
            const Expanded(child: Icon(Icons.chevron_right,
                size: 16, color: AppTheme.textTertiary)),
          ]),
        ),
      );
}
