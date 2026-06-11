import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../services/db_service.dart';

class ManageHallsScreen extends StatefulWidget {
  const ManageHallsScreen({super.key});
  @override
  State<ManageHallsScreen> createState() => _ManageHallsScreenState();
}

class _ManageHallsScreenState extends State<ManageHallsScreen> {
  final _dbService = DbService();
  final _searchCtrl = TextEditingController();
  String _search = '';
  bool _isLoading = false;

  List<Map<String, dynamic>> _halls = [];

  @override
  void initState() {
    super.initState();
    _loadHalls();
  }

  Future<void> _loadHalls() async {
    setState(() => _isLoading = true);
    final rows = await _dbService.getHalls();
    if (!mounted) return;
    setState(() {
      _halls = rows.map(_normalize).toList();
      _isLoading = false;
    });
  }

  Map<String, dynamic> _normalize(Map<String, dynamic> h) {
    const emojis = {
      'Event Hall': '🏛️', 'Conference': '💼', 'Training': '🎓', 'Banquet': '🎉',
    };
    return {
      'id': (h['id'] ?? '').toString(),
      'name': h['name'] ?? '-',
      'type': h['type'] ?? 'Event Hall',
      'capacity': (h['capacity'] ?? 0).toString(),
      'price': h['price'] ?? '-',
      'price_per_day': h['price_per_day'] ?? 0.0,
      'price_per_hr': h['price_per_hr'] ?? 0.0,
      'location': h['location'] ?? '-',
      'description': h['description'] ?? '',
      'image_url': h['image_url'] ?? '',
      'status': h['status'] ?? 'Available',
      'statusType': h['statusType'] ?? 'success',
      'amenities': h['amenities'] ?? <String>[],
      'active': h['isActive'] == true,
      'emoji': emojis[h['type']] ?? '🏛️',
    };
  }

  List<Map<String, dynamic>> get _filtered =>
      _halls.where((h) => h['name']!.toString().toLowerCase().contains(_search.toLowerCase())).toList();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Manage Halls'),
          leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 18), onPressed: () => Navigator.pop(context)),
          actions: [
            TextButton.icon(
              onPressed: () async {
                await Navigator.pushNamed(context, '/admin/add-hall');
                _loadHalls();
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Hall'),
              style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
            ),
          ],
        ),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _search = v),
              decoration: const InputDecoration(
                hintText: 'Search hall name...',
                prefixIcon: Icon(Icons.search, size: 18),
              ),
            ),
          ),
          Expanded(child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filtered.isEmpty
                  ? const Center(child: Text('No halls found',
                      style: TextStyle(color: AppTheme.textSecondary)))
                  : RefreshIndicator(
                      onRefresh: _loadHalls,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filtered.length,
                        itemBuilder: (_, i) => _buildCard(_filtered[i], i),
                      ),
                    )),
        ]),
      );

  Widget _buildCard(Map<String, dynamic> h, int i) {
    final isActive = h['active'] as bool;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(h['emoji']!, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(h['name']!, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600))),
                StatusBadge(label: isActive ? 'Active' : 'Inactive',
                    type: isActive ? StatusType.success : StatusType.danger),
              ]),
              Text('${h['capacity']} pax · ${h['price']} · ${h['location']}',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ])),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: OutlinedButton.icon(
              onPressed: () async {
                await Navigator.pushNamed(context, '/admin/add-hall', arguments: h);
                _loadHalls();
              },
              icon: const Icon(Icons.edit_outlined, size: 14),
              label: const Text('Edit', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 36), padding: const EdgeInsets.symmetric(horizontal: 8)),
            )),
            const SizedBox(width: 6),
            Expanded(child: OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.calendar_month_outlined, size: 14, color: AppTheme.textSecondary),
              label: const Text('Slots', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 36), padding: const EdgeInsets.symmetric(horizontal: 8),
                  side: BorderSide(color: AppTheme.cardBorder)),
            )),
            const SizedBox(width: 6),
            Expanded(child: isActive
                ? OutlinedButton.icon(
                    onPressed: () => _setActive(h, false),
                    icon: const Icon(Icons.block, size: 14, color: AppTheme.danger),
                    label: const Text('Deactivate', style: TextStyle(fontSize: 11, color: AppTheme.danger)),
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 36), padding: const EdgeInsets.symmetric(horizontal: 4),
                        side: const BorderSide(color: AppTheme.danger)),
                  )
                : OutlinedButton.icon(
                    onPressed: () => _setActive(h, true),
                    icon: const Icon(Icons.check_circle_outline, size: 14, color: AppTheme.success),
                    label: const Text('Activate', style: TextStyle(fontSize: 11, color: AppTheme.success)),
                    style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 36), padding: const EdgeInsets.symmetric(horizontal: 4),
                        side: const BorderSide(color: AppTheme.success)),
                  )),
            const SizedBox(width: 6),
            IconButton(
              onPressed: () => _confirmDelete(context, h),
              icon: const Icon(Icons.delete_outline, color: AppTheme.danger, size: 20),
              style: IconButton.styleFrom(
                  backgroundColor: AppTheme.dangerLight,
                  minimumSize: const Size(36, 36),
                  padding: EdgeInsets.zero),
            ),
          ]),
        ]),
      ),
    );
  }

  Future<void> _setActive(Map<String, dynamic> h, bool active) async {
    final ok = await _dbService.updateHall(h['id'].toString(), {'isActive': active});
    if (!mounted) return;
    if (ok) await _loadHalls();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? '${h['name']} ${active ? 'activated' : 'deactivated'}'
            : 'Failed to update hall'),
        backgroundColor: active ? AppTheme.success : AppTheme.danger));
  }

  void _confirmDelete(BuildContext context, Map<String, dynamic> h) => showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Delete hall?', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          content: Text('Are you sure you want to delete "${h['name']}"? This cannot be undone.',
              style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(context);
                final ok = await _dbService.deleteHall(h['id'].toString());
                if (ok) await _loadHalls();
                messenger.showSnackBar(SnackBar(
                    content: Text(ok ? '${h['name']} deleted' : 'Failed to delete hall'),
                    backgroundColor: AppTheme.danger));
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
}
