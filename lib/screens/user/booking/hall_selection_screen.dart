import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/shared_widgets.dart';
import '../../../services/app_events.dart';
import '../../../services/db_service.dart';
import '../../../services/session_service.dart';
import '../browse_screen.dart';
import '../profile_screen.dart';
import '../management/my_bookings_screen.dart';

class HallSelectionScreen extends StatefulWidget {
  const HallSelectionScreen({super.key});
  @override
  State<HallSelectionScreen> createState() => _HallSelectionScreenState();
}

class _HallSelectionScreenState extends State<HallSelectionScreen> {
  int _navIndex = 0;
  int _catIndex = 0;
  String _search = '';
  bool _isLoading = false;
  List<Map<String, dynamic>> _halls = [];

  final _cats = ['All', 'Event Hall', 'Conference', 'Training', 'Banquet'];
  final _dbService = DbService();

  @override
  void initState() {
    super.initState();
    _loadHalls();
    // Refresh when halls change (e.g. admin adds/edits/removes a hall).
    AppEvents.dataVersion.addListener(_loadHalls);
  }

  @override
  void dispose() {
    AppEvents.dataVersion.removeListener(_loadHalls);
    super.dispose();
  }

  Future<void> _loadHalls() async {
    setState(() => _isLoading = true);
    try {
      final dbHalls = await _dbService.getHalls(
        type: _catIndex == 0 ? null : _cats[_catIndex],
      );
      if (mounted) {
        setState(() {
          _halls = dbHalls;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _halls = [];
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_search.isEmpty) return _halls;
    final q = _search.toLowerCase();
    return _halls.where((h) => 
      h['name'].toString().toLowerCase().contains(q) || 
      h['location'].toString().toLowerCase().contains(q)
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _navIndex,
        children: [
          _HomeTab(
            cats: _cats,
            catIndex: _catIndex,
            onCatChanged: (i) {
              setState(() => _catIndex = i);
              _loadHalls();
            },
            filteredHalls: _filtered,
            search: _search,
            onSearch: (v) => setState(() => _search = v),
            onProfileTap: () => setState(() => _navIndex = 3),
            isLoading: _isLoading,
            onRefresh: _loadHalls,
          ),
          const BrowseScreen(),
          const MyBookingsScreen(isTab: true),
          const ProfileScreen(),
        ],
      ),
      bottomNavigationBar: UserBottomNav(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
      ),
    );
  }
}

class _HomeTab extends StatelessWidget {
  final List<String> cats;
  final int catIndex;
  final ValueChanged<int> onCatChanged;
  final List<Map<String, dynamic>> filteredHalls;
  final String search;
  final ValueChanged<String> onSearch;
  final VoidCallback onProfileTap;
  final bool isLoading;
  final Future<void> Function() onRefresh;

  const _HomeTab({
    required this.cats,
    required this.catIndex,
    required this.onCatChanged,
    required this.filteredHalls,
    required this.search,
    required this.onSearch,
    required this.onProfileTap,
    required this.isLoading,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      _header(context),
      Expanded(
        child: RefreshIndicator(
          onRefresh: onRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              FilterChipRow(
                chips: cats,
                selected: catIndex,
                onSelected: onCatChanged,
              ),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('${filteredHalls.length} venues found',
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.sort, size: 16),
                  label: const Text('Sort', style: TextStyle(fontSize: 13)),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
                ),
              ]),
              const SizedBox(height: 10),
              if (isLoading)
                const Center(child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(),
                ))
              else if (filteredHalls.isEmpty)
                const EmptyState(
                  title: 'No venues found',
                  subtitle: 'Try a different category or search term',
                  icon: Icons.search_off_outlined,
                )
              else
                ...filteredHalls.map((h) {
                  final name = h['name'] ?? 'Unknown Hall';
                  final location = h['location'] ?? 'No location';
                  final capacity = (h['capacity'] ?? 0).toString();
                  final rating = (h['rating'] ?? 0.0).toString();
                  
                  // Robust price handling
                  String price = 'N/A';
                  if (h['price'] is String) {
                    price = h['price'];
                  } else if (h['price_label'] != null) {
                    price = h['price_label'];
                  } else if (h['price'] != null && h['unit'] != null) {
                    price = 'RM ${h['price'].toInt()}/${h['unit']}';
                  } else if (h['price_per_day'] != null) {
                    price = 'RM ${h['price_per_day']}/day';
                  } else if (h['price_per_hr'] != null) {
                    price = 'RM ${h['price_per_hr']}/hr';
                  }
                  
                  final image = h['imageUrl'] ?? h['image_url'] ?? h['image'];
                  
                  return VenueCard(
                    name: name,
                    location: location,
                    capacity: capacity,
                    rating: rating,
                    price: price,
                    type: h['type'] ?? 'General',
                    status: (h['statusType'] ?? h['status_type']) == 'warning' ? StatusType.warning : StatusType.success,
                    statusLabel: h['status'] ?? h['status_label'] ?? 'Available',
                    icon: _getIcon(h['type']),
                    imageUrl: image,
                    onTap: () => Navigator.pushNamed(context, '/user/hall-detail', arguments: {
                      ...h,
                      'name': name,
                      'location': location,
                      'capacity': capacity,
                      'rating': rating,
                      'price': price,
                      'imageUrl': image,
                      'amenities': h['amenities'] ?? [],
                    }),
                  );
                }),
            ]),
          ),
        ),
      ),
    ]);
  }

  IconData _getIcon(String? type) {
    switch (type) {
      case 'Event Hall': return Icons.account_balance_outlined;
      case 'Conference': return Icons.business_center_outlined;
      case 'Training': return Icons.school_outlined;
      case 'Banquet': return Icons.celebration_outlined;
      default: return Icons.account_balance_outlined;
    }
  }

  Widget _header(BuildContext context) => Container(
        color: AppTheme.primary,
        padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16, right: 16, bottom: 16),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Hello, ${SessionService.instance.name.split(' ').first}',
                  style: const TextStyle(fontSize: 13, color: Color(0xFFB5D4F4))),
              const Text('Book a venue', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white)),
            ]),
            GestureDetector(
              onTap: onProfileTap,
              child: CircleAvatar(
                radius: 20, backgroundColor: const Color(0xFFB5D4F4),
                child: Text(SessionService.instance.initials,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.primaryDark)),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              onChanged: onSearch,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Search halls, location...',
                hintStyle: TextStyle(color: Color(0xFFB5D4F4)),
                prefixIcon: Icon(Icons.search, color: Color(0xFFB5D4F4), size: 18),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                fillColor: Colors.transparent,
              ),
            ),
          ),
        ]),
      );
}
