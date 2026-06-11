import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';

class AdminProfileScreen extends StatefulWidget {
  const AdminProfileScreen({super.key});
  @override
  State<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends State<AdminProfileScreen> {
  bool _emailAlerts = true;
  bool _bookingNotifs = true;
  bool _paymentNotifs = true;

  static const _admin = {
    'name': 'Admin User',
    'email': 'admin@eventspace.com',
    'phone': '+60 12 999 8888',
    'role': 'Super Admin',
    'joined': 'December 2024',
    'lastLogin': 'Today, 3:52 PM',
    'initials': 'AD',
    'totalHallsManaged': 8,
    'totalBookingsHandled': 142,
    'totalRevenue': 'RM 48,200',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: CustomScrollView(slivers: [
        _appBar(context),
        SliverToBoxAdapter(child: Column(children: [
          _profileCard(),
          const SizedBox(height: 16),
          _adminStats(),
          const SizedBox(height: 16),
          _section('Account Settings', [
            _tile(Icons.person_outline, 'Edit Profile',
                'Update your name, email, phone',
                const Color(0xFFFAEEDA), AppTheme.adminPrimary,
                () => _showEditProfile(context)),
            _tile(Icons.lock_outline, 'Change Password',
                'Update your login password',
                const Color(0xFFFAEEDA), AppTheme.adminPrimary,
                () => _showChangePassword(context)),
            _tile(Icons.admin_panel_settings_outlined, 'Role & Permissions',
                'Super Admin · Full access',
                AppTheme.primaryLight, AppTheme.primary,
                () => _toast('Role management coming soon')),
          ]),
          const SizedBox(height: 16),
          _section('Notification Preferences', [
            _toggleTile(Icons.email_outlined, 'Email Alerts',
                'New bookings and cancellations',
                const Color(0xFFFAEEDA), AppTheme.adminPrimary,
                _emailAlerts, (v) => setState(() => _emailAlerts = v)),
            _toggleTile(Icons.event_outlined, 'Booking Notifications',
                'Pending approvals and updates',
                AppTheme.primaryLight, AppTheme.primary,
                _bookingNotifs, (v) => setState(() => _bookingNotifs = v)),
            _toggleTile(Icons.payments_outlined, 'Payment Alerts',
                'Failed payments and refunds',
                AppTheme.successLight, AppTheme.success,
                _paymentNotifs, (v) => setState(() => _paymentNotifs = v)),
          ]),
          const SizedBox(height: 16),
          _section('System', [
            _tile(Icons.history_outlined, 'Activity Log',
                'Recent admin actions',
                AppTheme.surface, AppTheme.textSecondary,
                () => _toast('Activity log coming soon')),
            _tile(Icons.download_outlined, 'Export Data',
                'Download reports and records',
                AppTheme.successLight, AppTheme.success,
                () => Navigator.pushNamed(context, '/admin/reports')),
            _tile(Icons.help_outline, 'Help & Support',
                'Admin documentation',
                AppTheme.primaryLight, AppTheme.primary,
                () => _toast('Help coming soon')),
          ]),
          const SizedBox(height: 16),
          _logoutCard(context),
          const SizedBox(height: 32),
          const Text('EventSpace Admin v1.0.0',
              style: TextStyle(fontSize: 12, color: AppTheme.textTertiary)),
          const SizedBox(height: 24),
        ])),
      ]),
    );
  }

  // ── App Bar ────────────────────────────────────────────────────────────────
  SliverAppBar _appBar(BuildContext context) => SliverAppBar(
        pinned: true,
        backgroundColor: AppTheme.adminPrimary,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Admin Profile',
            style: TextStyle(color: Color(0xFFFAEEDA), fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Color(0xFFFAC775)),
            onPressed: () => _showEditProfile(context),
          ),
        ],
      );

  // ── Profile Card ───────────────────────────────────────────────────────────
  Widget _profileCard() => Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.cardBorder, width: 0.5),
          boxShadow: [BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Stack(clipBehavior: Clip.none, children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                    colors: [AppTheme.adminPrimary, Color(0xFF3D1E00)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(
                    color: AppTheme.adminPrimary.withOpacity(0.35),
                    blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: const Center(child: Text('AD',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white))),
            ),
            Positioned(bottom: 0, right: 0,
                child: Container(
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                      color: AppTheme.adminPrimary, shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2)),
                  child: const Icon(Icons.edit, size: 11, color: Colors.white),
                )),
          ]),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(_admin['name'] as String,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: const Color(0xFFFAEEDA),
                    borderRadius: BorderRadius.circular(6)),
                child: Text(_admin['role'] as String,
                    style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w700,
                        color: AppTheme.adminPrimary)),
              ),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.email_outlined, size: 13, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Expanded(child: Text(_admin['email'] as String,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 2),
            Row(children: [
              const Icon(Icons.access_time, size: 13, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text('Last login: ${_admin['lastLogin']}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ]),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: AppTheme.successLight, borderRadius: BorderRadius.circular(6)),
              child: Text('Member since ${_admin['joined']}',
                  style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.success)),
            ),
          ])),
        ]),
      );

  // ── Admin Stats ────────────────────────────────────────────────────────────
  Widget _adminStats() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          _statCard('${_admin['totalHallsManaged']}', 'Halls\nManaged',
              Icons.meeting_room_outlined, AppTheme.primaryLight, AppTheme.primary),
          const SizedBox(width: 10),
          _statCard('${_admin['totalBookingsHandled']}', 'Bookings\nHandled',
              Icons.event_available_outlined, AppTheme.successLight, AppTheme.success),
          const SizedBox(width: 10),
          _statCard('${_admin['totalRevenue']}', 'Revenue\nCollected',
              Icons.payments_outlined, const Color(0xFFFAEEDA), AppTheme.adminPrimary),
        ]),
      );

  Widget _statCard(String value, String label, IconData icon, Color bg, Color fg) =>
      Expanded(child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: fg.withOpacity(0.15))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 20, color: fg),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(
              fontSize: value.length > 6 ? 12 : 18,
              fontWeight: FontWeight.w900, color: fg)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(
              fontSize: 10, color: fg.withOpacity(0.8),
              fontWeight: FontWeight.w500, height: 1.3)),
        ]),
      ));

  // ── Section ────────────────────────────────────────────────────────────────
  Widget _section(String title, List<Widget> tiles) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SectionHeader(title: title),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.cardBorder, width: 0.5),
            ),
            child: Column(children: List.generate(tiles.length, (i) => Column(children: [
              tiles[i],
              if (i < tiles.length - 1) const Divider(height: 0, indent: 56),
            ]))),
          ),
        ]),
      );

  Widget _tile(IconData icon, String title, String subtitle,
      Color iconBg, Color iconFg, VoidCallback onTap) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(children: [
            Container(width: 38, height: 38,
                decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 18, color: iconFg)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ])),
            const Icon(Icons.chevron_right, size: 18, color: AppTheme.textTertiary),
          ]),
        ),
      );

  Widget _toggleTile(IconData icon, String title, String subtitle,
      Color iconBg, Color iconFg, bool value, ValueChanged<bool> onChanged) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(children: [
          Container(width: 38, height: 38,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 18, color: iconFg)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ])),
          Switch(value: value, onChanged: onChanged,
              activeColor: AppTheme.adminPrimary),
        ]),
      );

  // ── Logout Card ────────────────────────────────────────────────────────────
  Widget _logoutCard(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GestureDetector(
          onTap: () => _confirmLogout(context),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.dangerLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.danger.withOpacity(0.3)),
            ),
            child: const Row(children: [
              Icon(Icons.logout, color: AppTheme.danger, size: 22),
              SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Logout', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.danger)),
                Text('Sign out of admin panel', style: TextStyle(fontSize: 12, color: AppTheme.danger)),
              ])),
              Icon(Icons.chevron_right, color: AppTheme.danger, size: 18),
            ]),
          ),
        ),
      );

  // ── Modals ─────────────────────────────────────────────────────────────────
  void _showEditProfile(BuildContext context) => showModalBottomSheet(
        context: context, isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => Padding(
          padding: EdgeInsets.only(
              left: 20, right: 20, top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: AppTheme.cardBorder, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Text('Edit Admin Profile',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            TextFormField(initialValue: _admin['name'] as String,
                decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline, size: 18))),
            const SizedBox(height: 12),
            TextFormField(initialValue: _admin['email'] as String,
                decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined, size: 18))),
            const SizedBox(height: 12),
            TextFormField(initialValue: _admin['phone'] as String,
                decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone_outlined, size: 18))),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _toast('Profile updated!');
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.adminPrimary),
              child: const Text('Save Changes'),
            ),
          ]),
        ),
      );

  void _showChangePassword(BuildContext context) => showModalBottomSheet(
        context: context, isScrollControlled: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => Padding(
          padding: EdgeInsets.only(
              left: 20, right: 20, top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: AppTheme.cardBorder, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            const Text('Change Password',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 16),
            TextFormField(obscureText: true,
                decoration: const InputDecoration(labelText: 'Current password', prefixIcon: Icon(Icons.lock_outline, size: 18))),
            const SizedBox(height: 12),
            TextFormField(obscureText: true,
                decoration: const InputDecoration(labelText: 'New password', prefixIcon: Icon(Icons.lock_outline, size: 18))),
            const SizedBox(height: 12),
            TextFormField(obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm new password', prefixIcon: Icon(Icons.lock_outline, size: 18))),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _toast('Password changed successfully!');
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.adminPrimary),
              child: const Text('Update Password'),
            ),
          ]),
        ),
      );

  void _confirmLogout(BuildContext context) => showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Logout?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          content: const Text('Sign out of the admin panel?',
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Stay')),
            ElevatedButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
              child: const Text('Yes, Logout'),
            ),
          ],
        ),
      );

  void _toast(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg), backgroundColor: AppTheme.adminPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
}
