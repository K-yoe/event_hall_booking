import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../services/db_service.dart';

class GuestHomeScreen extends StatefulWidget {
  const GuestHomeScreen({super.key});
  @override
  State<GuestHomeScreen> createState() => _GuestHomeScreenState();
}

class _GuestHomeScreenState extends State<GuestHomeScreen> {
  int _selectedCategory = 0;
  bool _isLoading = true;
  final _categories = [
    (Icons.grid_view_outlined, 'All'),
    (Icons.account_balance_outlined, 'Event Hall'),
    (Icons.business_center_outlined, 'Conference'),
    (Icons.school_outlined, 'Training'),
    (Icons.celebration_outlined, 'Banquet'),
  ];

  final _dbService = DbService();
  List<Map<String, dynamic>> _allVenues = [];

  @override
  void initState() {
    super.initState();
    _loadVenues();
  }

  Future<void> _loadVenues() async {
    final rows = await _dbService.getHalls();
    if (!mounted) return;
    setState(() {
      _allVenues = rows.map(_toVenue).toList();
      _isLoading = false;
    });
  }

  // Map a DB hall row onto the fields the guest VenueCard expects.
  Map<String, dynamic> _toVenue(Map<String, dynamic> h) {
    final perDay = (h['price_per_day'] is num) ? (h['price_per_day'] as num).toDouble() : 0.0;
    final perHr = (h['price_per_hr'] is num) ? (h['price_per_hr'] as num).toDouble() : 0.0;
    final price = (h['price'] as String?)?.isNotEmpty == true
        ? h['price'] as String
        : perDay > 0
            ? 'RM ${perDay.toStringAsFixed(0)}/day'
            : 'RM ${perHr.toStringAsFixed(0)}/hr';
    final type = (h['type'] ?? 'Event Hall').toString();
    final isWarn = (h['statusType'] ?? 'success') == 'warning';
    return {
      'name': h['name'] ?? 'Unknown Hall',
      'location': h['location'] ?? '-',
      'capacity': (h['capacity'] ?? 0).toString(),
      'rating': (h['rating'] ?? 0.0).toString(),
      'price': price,
      'type': type,
      'statusLabel': h['status'] ?? 'Available',
      'status': isWarn ? StatusType.warning : StatusType.success,
      'icon': _iconFor(type),
      'emojiBg': isWarn ? AppTheme.warningLight : AppTheme.primaryLight,
      'imageUrl': h['imageUrl'] ?? h['image_url'],
    };
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'Conference': return Icons.business_center_outlined;
      case 'Training': return Icons.school_outlined;
      case 'Banquet': return Icons.celebration_outlined;
      default: return Icons.account_balance_outlined;
    }
  }

  List<Map<String, dynamic>> get _filteredVenues {
    if (_selectedCategory == 0) return _allVenues;
    final categoryName = _categories[_selectedCategory].$2;
    return _allVenues.where((v) => v['type'] == categoryName).toList();
  }

  @override
  Widget build(BuildContext context) {
    final selectedCat = _categories[_selectedCategory].$2;
    final title = selectedCat == 'All' ? 'Featured Halls' : 'Featured ${selectedCat}s';

    return Scaffold(
      body: Column(children: [
        _buildHeader(),
        Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildCategories(),
            const SizedBox(height: 20),
            SectionHeader(title: title),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_filteredVenues.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: Text('No venues available',
                    style: TextStyle(color: AppTheme.textSecondary))),
              ),
            ..._filteredVenues.map((v) => VenueCard(
              name: v['name'] as String,
              location: v['location'] as String,
              capacity: v['capacity'] as String,
              rating: v['rating'] as String,
              price: v['price'] as String,
              type: v['type'] as String,
              statusLabel: v['statusLabel'] as String,
              status: v['status'] as StatusType,
              icon: v['icon'] as IconData,
              imageUrl: v['imageUrl'] as String?,
              emojiBg: v['emojiBg'] as Color,
              onTap: () => _showLoginPrompt(context),
            )),
            const SizedBox(height: 4),
            _buildLoginPromptBanner(),
          ]),
        )),
      ]),
    );
  }

  Widget _buildHeader() => Container(
        color: AppTheme.primary,
        padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16, right: 16, bottom: 16),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('EventSpace', style: TextStyle(fontSize: 13, color: Color(0xFFB5D4F4))),
              Text('Find your perfect venue',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white)),
            ]),
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/login'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(children: [
                  Icon(Icons.person_outline, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text('Login', style: TextStyle(color: Colors.white, fontSize: 13)),
                ]),
              ),
            ),
          ]),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/login'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(children: [
                Icon(Icons.search, color: Color(0xFFB5D4F4), size: 18),
                SizedBox(width: 10),
                Text('Search halls, location, capacity...',
                    style: TextStyle(color: Color(0xFFB5D4F4), fontSize: 14)),
              ]),
            ),
          ),
        ]),
      );

  Widget _buildCategories() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SectionHeader(title: 'Categories'),
        Row(children: List.generate(_categories.length, (i) => Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedCategory = i),
                child: Container(
                  margin: EdgeInsets.only(right: i < _categories.length - 1 ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _selectedCategory == i ? AppTheme.primaryLight : Colors.white,
                    border: Border.all(
                        color: _selectedCategory == i ? AppTheme.primary : AppTheme.cardBorder),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(children: [
                    Icon(_categories[i].$1,
                        size: 26,
                        color: _selectedCategory == i ? AppTheme.primary : AppTheme.textSecondary),
                    const SizedBox(height: 4),
                    Text(_categories[i].$2,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: _selectedCategory == i ? AppTheme.primary : AppTheme.textSecondary),
                        textAlign: TextAlign.center),
                  ]),
                ),
              ),
            ))),
      ]);

  Widget _buildLoginPromptBanner() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF9EC),
          border: Border.all(color: const Color(0xFFFAC775)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Login to book a venue',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF633806))),
          const SizedBox(height: 4),
          const Text('Register for free to view real-time availability and make a booking.',
              style: TextStyle(fontSize: 13, color: Color(0xFF854F0B))),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              child: const Text('Login'),
            )),
            const SizedBox(width: 10),
            Expanded(child: OutlinedButton(
              onPressed: () => Navigator.pushNamed(context, '/register'),
              child: const Text('Register'),
            )),
          ]),
        ]),
      );

  void _showLoginPrompt(BuildContext context) => showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Login required', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            const Text('Please login or register to view availability and book this venue.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              child: const Text('Login'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.pushNamed(context, '/register'),
              child: const Text('Register for free'),
            ),
          ]),
        ),
      );
}
