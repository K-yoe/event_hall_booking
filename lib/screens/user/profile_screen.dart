import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../services/app_events.dart';
import '../../services/db_service.dart';
import '../../services/session_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notifications = true;
  bool _emailUpdates = true;
  bool _darkMode = false;

  final _db = DbService();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  Map<String, dynamic> _user = {
    'name': 'Guest', 'email': '', 'phone': '-', 'initials': 'U',
    'joined': '-', 'totalBookings': 0, 'totalSpent': 'RM 0', 'upcomingBookings': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadProfile();
    // Reload stats whenever bookings/payments/profile change in any tab.
    AppEvents.dataVersion.addListener(_loadProfile);
  }

  @override
  void dispose() {
    AppEvents.dataVersion.removeListener(_loadProfile);
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final s = SessionService.instance;
    final userEmail = s.email.toLowerCase();
    // All stats come from the stored user record so the profile mirrors exactly
    // what's in the database (admin Manage Users reads the same columns).
    final user = await _db.getUserByEmail(userEmail) ?? s.currentUser ?? {};
    if (!mounted) return;
    setState(() {
      _user = {
        'name': s.name,
        'email': s.email,
        'phone': (user['phone'] ?? '-').toString(),
        'initials': s.initials,
        'joined': (user['joined'] ?? '-').toString(),
        'totalBookings': user['bookings'] ?? 0,
        'totalSpent': (user['spent'] ?? 'RM 0').toString(),
        'upcomingBookings': user['upcoming'] ?? 0,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: CustomScrollView(slivers: [
        _buildAppBar(),
        SliverToBoxAdapter(child: Column(children: [
          _buildProfileCard(),
          const SizedBox(height: 16),
          _buildStats(),
          const SizedBox(height: 16),
          _buildSection('My Account', [
            _tile(Icons.calendar_today_outlined, 'My Bookings', 'View and manage bookings',
                AppTheme.primaryLight, AppTheme.primary,
                () => Navigator.pushNamed(context, '/user/my-bookings')),
            _tile(Icons.receipt_long_outlined, 'Payment History', 'Transactions & receipts',
                AppTheme.successLight, AppTheme.success,
                () => Navigator.pushNamed(context, '/payment/history')),
            _tile(Icons.favorite_outline, 'Saved Venues', 'Your favourited halls',
                const Color(0xFFFBEAF0), const Color(0xFF72243E),
                () => _comingSoon()),
            _tile(Icons.star_outline, 'My Reviews', 'Feedback you\'ve shared',
                const Color(0xFFFFF9EC), const Color(0xFF854F0B),
                () => _comingSoon()),
          ]),
          const SizedBox(height: 16),
          _buildSection('Preferences', [
            _toggleTile(Icons.notifications_outlined, 'Push Notifications',
                'Booking reminders & updates', AppTheme.primaryLight, AppTheme.primary,
                _notifications, (v) => setState(() => _notifications = v)),
            _toggleTile(Icons.email_outlined, 'Email Updates',
                'Confirmation & receipts', AppTheme.successLight, AppTheme.success,
                _emailUpdates, (v) => setState(() => _emailUpdates = v)),
            _toggleTile(Icons.dark_mode_outlined, 'Dark Mode',
                'Switch appearance', const Color(0xFFF1EFE8), const Color(0xFF444441),
                _darkMode, (v) => setState(() => _darkMode = v)),
          ]),
          const SizedBox(height: 16),
          _buildSection('Support', [
            _tile(Icons.help_outline, 'Help & FAQ', 'Common questions',
                AppTheme.primaryLight, AppTheme.primary, () => _comingSoon()),
            _tile(Icons.support_agent_outlined, 'Contact Support', 'Get help from our team',
                AppTheme.successLight, AppTheme.success, () => _comingSoon()),
            _tile(Icons.privacy_tip_outlined, 'Privacy Policy', 'How we use your data',
                const Color(0xFFF1EFE8), const Color(0xFF444441), () => _comingSoon()),
            _tile(Icons.description_outlined, 'Terms of Service', 'Usage terms',
                const Color(0xFFF1EFE8), const Color(0xFF444441), () => _comingSoon()),
          ]),
          const SizedBox(height: 16),
          _buildLogoutCard(),
          const SizedBox(height: 32),
          const Text('EventSpace v1.0.0',
              style: TextStyle(fontSize: 12, color: AppTheme.textTertiary)),
          const SizedBox(height: 24),
        ])),
      ]),
    );
  }

  SliverAppBar _buildAppBar() => SliverAppBar(
        expandedHeight: 140,
        pinned: true,
        backgroundColor: AppTheme.primary,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.home_outlined, color: Colors.white),
          tooltip: 'Back to Lobby',
          onPressed: _confirmLogout,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            onPressed: _showEditProfile,
          ),
        ],
        flexibleSpace: FlexibleSpaceBar(
          background: Container(
            color: AppTheme.primary,
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 10, left: 56, right: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
              Text('My Profile',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
              SizedBox(height: 4),
              Text('Manage your account and preferences',
                  style: TextStyle(fontSize: 13, color: Color(0xFFB5D4F4))),
            ]),
          ),
        ),
      );

  Widget _buildProfileCard() => Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.cardBorder, width: 0.5),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Stack(clipBehavior: Clip.none, children: [
            Container(
              width: 70, height: 70,
              decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [AppTheme.primary, AppTheme.primaryDark],
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))]),
              child: Center(
                child: Text(_user['initials'] as String,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
              ),
            ),
            Positioned(
              bottom: 0, right: 0,
              child: GestureDetector(
                onTap: _showEditProfile,
                child: Container(
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                      color: AppTheme.primary, shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2)),
                  child: const Icon(Icons.edit, size: 11, color: Colors.white),
                ),
              ),
            ),
          ]),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_user['name'] as String,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 3),
            Row(children: [
              const Icon(Icons.email_outlined, size: 13, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Expanded(child: Text(_user['email'] as String,
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary), overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 2),
            Row(children: [
              const Icon(Icons.phone_outlined, size: 13, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text(_user['phone'] as String,
                  style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
            ]),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: AppTheme.successLight, borderRadius: BorderRadius.circular(6)),
              child: Text('Member since ${_user['joined']}',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.success)),
            ),
          ])),
        ]),
      );

  Widget _buildStats() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(children: [
          _statCard('${_user['totalBookings']}', 'Total\nBookings',
              Icons.event_available_outlined, AppTheme.primaryLight, AppTheme.primary),
          const SizedBox(width: 10),
          _statCard('${_user['upcomingBookings']}', 'Upcoming\nBookings',
              Icons.upcoming_outlined, AppTheme.warningLight, AppTheme.warning),
          const SizedBox(width: 10),
          _statCard('${_user['totalSpent']}', 'Total\nSpent',
              Icons.payments_outlined, AppTheme.successLight, AppTheme.success),
        ]),
      );

  Widget _statCard(String value, String label, IconData icon, Color bg, Color fg) =>
      Expanded(child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: bg, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: fg.withValues(alpha: 0.15))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 20, color: fg),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: value.length > 6 ? 13 : 18,
              fontWeight: FontWeight.w900, color: fg)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: fg.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500, height: 1.3)),
        ]),
      ));

  Widget _buildSection(String title, List<Widget> tiles) => Padding(
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
              if (i < tiles.length - 1)
                const Divider(height: 0, indent: 56),
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
          Switch(value: value, onChanged: onChanged, activeTrackColor: AppTheme.primary),
        ]),
      );

  Widget _buildLogoutCard() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GestureDetector(
          onTap: _confirmLogout,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.dangerLight,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
            ),
            child: const Row(children: [
              Icon(Icons.logout, color: AppTheme.danger, size: 22),
              SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Back to Lobby', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.danger)),
                Text('Sign out and return to home screen', style: TextStyle(fontSize: 12, color: AppTheme.danger)),
              ])),
              Icon(Icons.chevron_right, color: AppTheme.danger, size: 18),
            ]),
          ),
        ),
      );

  void _showEditProfile() {
    _nameCtrl.text = _user['name'] as String;
    _emailCtrl.text = _user['email'] as String;
    _phoneCtrl.text = _user['phone'] as String;
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppTheme.cardBorder, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          const Text('Edit Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Icons.person_outline, size: 18))),
          const SizedBox(height: 12),
          TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(labelText: 'Phone number', prefixIcon: Icon(Icons.phone_outlined, size: 18))),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saveProfile,
            child: const Text('Save Changes'),
          ),
        ]),
      ),
    );
  }

  Future<void> _saveProfile() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final session = SessionService.instance;
    final id = (session.currentUser?['id'] ?? '').toString();
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();

    if (id.isNotEmpty && id != 'admin') {
      await _db.updateUser(id, {'name': name, 'phone': phone});
    }
    // Update in-memory session so the rest of the app reflects the change.
    session.currentUser?['name'] = name;
    session.currentUser?['phone'] = phone;

    navigator.pop();
    await _loadProfile();
    messenger.showSnackBar(const SnackBar(
        content: Text('Profile updated!'), backgroundColor: AppTheme.success));
  }

  void _confirmLogout() => showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Logout?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          content: const Text('Are you sure you want to sign out of your account?',
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Stay')),
            ElevatedButton(
              onPressed: () async {
                await SessionService.instance.logout();
                if (!context.mounted) return;
                Navigator.pushNamedAndRemoveUntil(context, '/', (_) => false);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
              child: const Text('Yes, Logout'),
            ),
          ],
        ),
      );

  void _comingSoon() => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Coming soon!'),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
}
