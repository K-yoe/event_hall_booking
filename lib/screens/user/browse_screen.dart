import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../widgets/shared_widgets.dart';
import '../../services/app_events.dart';
import '../../services/db_service.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});
  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  int _catIndex = 0;
  String _search = '';
  String _sortBy = 'Recommended';
  RangeValues _priceRange = const RangeValues(0, 5000);
  int _minCapacity = 0;

  final _cats = ['All', 'Event Hall', 'Conference', 'Training', 'Banquet'];
  final _dbService = DbService();

  List<Map<String, dynamic>> _halls = [];

  @override
  void initState() {
    super.initState();
    _loadHalls();
    // Refresh when halls change (e.g. admin adds/edits a hall).
    AppEvents.dataVersion.addListener(_loadHalls);
  }

  @override
  void dispose() {
    AppEvents.dataVersion.removeListener(_loadHalls);
    super.dispose();
  }

  Future<void> _loadHalls() async {
    final rows = await _dbService.getHalls();
    if (!mounted) return;
    setState(() => _halls = rows.map(_normalize).toList());
  }

  Map<String, dynamic> _normalize(Map<String, dynamic> h) {
    final perDay = (h['price_per_day'] is num) ? (h['price_per_day'] as num).toDouble() : 0.0;
    final perHr = (h['price_per_hr'] is num) ? (h['price_per_hr'] as num).toDouble() : 0.0;
    final isDay = perDay > 0;
    final amenities = h['amenities'];
    return {
      'id': (h['id'] ?? '').toString(),
      'name': h['name'] ?? 'Unknown Hall',
      'location': h['location'] ?? '-',
      'capacity': (h['capacity'] is int) ? h['capacity'] : int.tryParse('${h['capacity']}') ?? 0,
      'rating': (h['rating'] is num) ? (h['rating'] as num).toDouble() : 0.0,
      'reviews': h['reviewCount'] ?? 0,
      'price': isDay ? perDay : perHr,
      'unit': isDay ? 'day' : 'hr',
      'type': h['type'] ?? 'General',
      'status': h['status'] ?? 'Available',
      'statusType': h['statusType'] ?? 'success',
      'image': h['imageUrl'] ?? h['image_url'],
      'reviewCount': h['reviewCount'] ?? 0,
      'description': h['description'] ?? '',
      'amenities': (amenities is List) ? amenities : <String>[],
    };
  }

  List<Map<String, dynamic>> get _filtered {
    var list = List<Map<String, dynamic>>.from(_halls);

    // Category filter
    if (_catIndex > 0) {
      list = list.where((h) => h['type'] == _cats[_catIndex]).toList();
    }

    // Search filter
    if (_search.isNotEmpty) {
      final q = _search.toLowerCase();
      list = list.where((h) =>
          h['name'].toString().toLowerCase().contains(q) ||
          h['location'].toString().toLowerCase().contains(q)).toList();
    }

    // Capacity filter
    if (_minCapacity > 0) {
      list = list.where((h) => (h['capacity'] as int) >= _minCapacity).toList();
    }

    // Sort
    switch (_sortBy) {
      case 'Price: Low to High':
        list.sort((a, b) => (a['price'] as double).compareTo(b['price'] as double));
        break;
      case 'Price: High to Low':
        list.sort((a, b) => (b['price'] as double).compareTo(a['price'] as double));
        break;
      case 'Rating':
        list.sort((a, b) => (b['rating'] as double).compareTo(a['rating'] as double));
        break;
      case 'Capacity':
        list.sort((a, b) => (b['capacity'] as int).compareTo(a['capacity'] as int));
        break;
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Column(children: [
        _buildHeader(),
        Expanded(child: RefreshIndicator(
          onRefresh: _loadHalls,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Category chips
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 0, 0),
                child: FilterChipRow(
                  chips: _cats,
                  selected: _catIndex,
                  onSelected: (i) => setState(() => _catIndex = i),
                ),
              ),
              // Count + sort row
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${_filtered.length} venues found',
                        style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
                    TextButton.icon(
                      onPressed: _showSortSheet,
                      icon: const Icon(Icons.sort, size: 16),
                      label: Text(_sortBy == 'Recommended' ? 'Sort' : _sortBy.split(':').first.trim(),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      style: TextButton.styleFrom(foregroundColor: AppTheme.primary),
                    ),
                  ],
                ),
              ),
              // Hall cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _filtered.isEmpty
                    ? EmptyState(
                        title: 'No venues found',
                        subtitle: 'Try a different category or search term',
                        icon: Icons.meeting_room_outlined,
                        actionLabel: 'Clear filters',
                        onAction: () => setState(() {
                          _catIndex = 0;
                          _search = '';
                          _sortBy = 'Recommended';
                          _minCapacity = 0;
                        }),
                      )
                    : Column(children: [
                        const SizedBox(height: 4),
                        ..._filtered.map((h) {
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
                        const SizedBox(height: 20),
                      ]),
              ),
            ]),
          ),
        )),
      ]),
    );
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

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: AppTheme.primary,
      padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 12,
          left: 16, right: 16, bottom: 16),
      child: Column(children: [
        // Title row
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Browse Venues',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
          GestureDetector(
            onTap: _showFilterSheet,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20)),
              child: Row(children: const [
                Icon(Icons.tune, color: Colors.white, size: 16),
                SizedBox(width: 5),
                Text('Filters', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 12),
        // Search bar
        GestureDetector(
          onTap: () => _showSearch(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12)),
            child: Row(children: [
              const Icon(Icons.search, color: AppTheme.textTertiary, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(
                _search.isEmpty ? 'Search halls, location...' : _search,
                style: TextStyle(
                    color: _search.isEmpty ? AppTheme.textTertiary : AppTheme.textPrimary,
                    fontSize: 14),
              )),
              if (_search.isNotEmpty)
                GestureDetector(
                  onTap: () => setState(() => _search = ''),
                  child: const Icon(Icons.close, size: 18, color: AppTheme.textTertiary),
                ),
            ]),
          ),
        ),
      ]),
    );
  }

  void _showSearch() {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            left: 20, right: 20, top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: AppTheme.cardBorder, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          TextField(
            autofocus: true,
            onChanged: (v) => setState(() => _search = v),
            decoration: InputDecoration(
              hintText: 'Search halls, location...',
              prefixIcon: const Icon(Icons.search, size: 18),
              suffixIcon: IconButton(
                icon: const Icon(Icons.close, size: 18),
                onPressed: () { setState(() => _search = ''); Navigator.pop(context); },
              ),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Search'),
          ),
        ]),
      ),
    );
  }

  // ── Sort sheet ────────────────────────────────────────────────────────────
  void _showSortSheet() {
    final opts = ['Recommended', 'Price: Low to High', 'Price: High to Low', 'Rating', 'Capacity'];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 40, height: 4, alignment: Alignment.center,
              decoration: BoxDecoration(color: AppTheme.cardBorder, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('Sort by', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          ...opts.map((o) => GestureDetector(
                onTap: () { setState(() => _sortBy = o); Navigator.pop(context); },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(
                    color: _sortBy == o ? AppTheme.primaryLight : AppTheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _sortBy == o ? AppTheme.primary : AppTheme.cardBorder, width: _sortBy == o ? 1.5 : 0.5),
                  ),
                  child: Row(children: [
                    Icon(_sortBy == o ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                        size: 18, color: _sortBy == o ? AppTheme.primary : AppTheme.textTertiary),
                    const SizedBox(width: 10),
                    Text(o, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
                        color: _sortBy == o ? AppTheme.primary : AppTheme.textPrimary)),
                  ]),
                ),
              )),
        ]),
      ),
    );
  }

  // ── Filter sheet ──────────────────────────────────────────────────────────
  void _showFilterSheet() {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(builder: (ctx, setS) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 40, height: 4, alignment: Alignment.center,
              decoration: BoxDecoration(color: AppTheme.cardBorder, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            TextButton(onPressed: () {
              setState(() { _minCapacity = 0; _priceRange = const RangeValues(0, 5000); });
              setS(() {});
            }, child: const Text('Reset all')),
          ]),
          const SizedBox(height: 14),
          const Text('Minimum capacity', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(spacing: 8, children: [0, 20, 50, 100, 200, 300].map((cap) => GestureDetector(
                onTap: () { setS(() => _minCapacity = cap); setState(() => _minCapacity = cap); },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: _minCapacity == cap ? AppTheme.primaryLight : Colors.white,
                    border: Border.all(color: _minCapacity == cap ? AppTheme.primary : AppTheme.cardBorder),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(cap == 0 ? 'Any' : '$cap+ pax',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                          color: _minCapacity == cap ? AppTheme.primary : AppTheme.textSecondary)),
                ),
              )).toList()),
          const SizedBox(height: 16),
          const Text('Price range (RM/day)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          RangeSlider(
            values: _priceRange,
            min: 0, max: 5000,
            divisions: 20,
            activeColor: AppTheme.primary,
            labels: RangeLabels('RM ${_priceRange.start.toInt()}', 'RM ${_priceRange.end.toInt()}'),
            onChanged: (v) { setS(() => _priceRange = v); setState(() => _priceRange = v); },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Show ${_filtered.length} results'),
          ),
        ]),
      )),
    );
  }
}
