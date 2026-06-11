import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../services/db_service.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});
  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  String _search = '';
  int _filterIndex = 0;
  bool _isLoading = false;
  final _filters = ['All', 'Active', 'Suspended'];
  final _dbService = DbService();

  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final rows = await _dbService.getUsers();
    if (!mounted) return;
    setState(() {
      _users = rows;
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _filtered {
    var list = _users.where((u) {
      if (_filterIndex == 1) return u['status'] == 'Active';
      if (_filterIndex == 2) return u['status'] == 'Suspended';
      return true;
    }).toList();
    if (_search.isNotEmpty) {
      list = list.where((u) =>
          u['name']!.toString().toLowerCase().contains(_search.toLowerCase()) ||
          u['email']!.toString().toLowerCase().contains(_search.toLowerCase())).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Manage Users'),
          leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18), onPressed: () => Navigator.pop(context)),
        ),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: const InputDecoration(
                hintText: 'Search name or email...',
                prefixIcon: Icon(Icons.search, size: 18),
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
            child: Text('${_filtered.length} users', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          ),
          const SizedBox(height: 8),
          Expanded(child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
                  ? const Center(child: Text('No users found',
                      style: TextStyle(color: AppTheme.textSecondary)))
                  : RefreshIndicator(
                      onRefresh: _loadUsers,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) => _buildCard(_filtered[i]),
                      ),
                    )),
        ]),
      );

  Widget _buildCard(Map<String, dynamic> u) {
    final isActive = u['status'] == 'Active';
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Color(u['avatarColor'] as int),
              child: Text(u['initials']!, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(u['textColor'] as int))),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(u['name']!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                StatusBadge(label: u['status']!, type: isActive ? StatusType.success : StatusType.danger),
              ]),
              Text(u['email']!, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              Text('${u['bookings']} bookings · ${u['spent']}', style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary)),
            ])),
          ]),
          const Divider(height: 16),
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: () => _showUserDetail(context, u),
              icon: const Icon(Icons.person_outline, size: 14),
              label: const Text('View profile', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 34), padding: const EdgeInsets.symmetric(horizontal: 8)),
            )),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton.icon(
              onPressed: () => _toggleStatus(u),
              icon: Icon(isActive ? Icons.block : Icons.check_circle_outline, size: 14, color: isActive ? AppTheme.danger : AppTheme.success),
              label: Text(isActive ? 'Suspend' : 'Activate',
                  style: TextStyle(fontSize: 12, color: isActive ? AppTheme.danger : AppTheme.success)),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 34), padding: const EdgeInsets.symmetric(horizontal: 8),
                  side: BorderSide(color: isActive ? AppTheme.danger : AppTheme.success)),
            )),
          ]),
        ]),
      ),
    );
  }

  Future<void> _toggleStatus(Map<String, dynamic> u) async {
    final newStatus = u['status'] == 'Active' ? 'Suspended' : 'Active';
    final ok = await _dbService.updateUserStatus(u['id'].toString(), newStatus);
    if (!mounted) return;
    if (ok) await _loadUsers();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok ? '${u['name']} $newStatus' : 'Failed to update user'),
        backgroundColor: newStatus == 'Active' ? AppTheme.success : AppTheme.danger));
  }

  void _showUserDetail(BuildContext context, Map<String, dynamic> u) => showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Color(u['avatarColor'] as int),
              child: Text(u['initials']!, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20, color: Color(u['textColor'] as int))),
            ),
            const SizedBox(height: 12),
            Text(u['name']!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            Text(u['email']!, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
            const SizedBox(height: 20),
            _detailRow(Icons.phone_outlined, u['phone']!),
            _detailRow(Icons.calendar_today_outlined, 'Joined: ${u['joined']}'),
            _detailRow(Icons.event_note_outlined, '${u['bookings']} total bookings'),
            _detailRow(Icons.attach_money, 'Total spent: ${u['spent']}'),
            const SizedBox(height: 20),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ]),
        ),
      );

  Widget _detailRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Icon(icon, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
        ]),
      );
}
