import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/shared_widgets.dart';

class HallDetailScreen extends StatefulWidget {
  const HallDetailScreen({super.key});
  @override
  State<HallDetailScreen> createState() => _HallDetailScreenState();
}

class _HallDetailScreenState extends State<HallDetailScreen> {
  bool _saved = false;

  @override
  Widget build(BuildContext context) {
    final hall = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ?? {
      'name': 'Grand Ballroom A', 'location': 'KL Sentral Convention',
      'capacity': '500', 'rating': '4.8', 'price': 'RM 2,500/day',
      'type': 'Event Hall', 'status': 'Available', 'icon': Icons.account_balance_outlined,
      'amenities': ['👥 500 pax', '📽 Projector', '🎤 PA System', '❄️ AC', '🅿️ Parking', '☕ Catering opt.'],
    };

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppTheme.primary,
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.black87),
              ),
            ),
            actions: [
              GestureDetector(
                onTap: () => setState(() => _saved = !_saved),
                child: Container(
                  margin: const EdgeInsets.all(8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), shape: BoxShape.circle),
                  child: Icon(_saved ? Icons.favorite : Icons.favorite_border,
                      size: 18, color: _saved ? Colors.red : Colors.black87),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: hall['imageUrl'] != null
                  ? CachedNetworkImage(
                      imageUrl: hall['imageUrl'] as String,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppTheme.primaryLight, AppTheme.primaryLight.withBlue(220)],
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                            child: Icon(hall['icon'] as IconData? ?? Icons.account_balance_outlined,
                                size: 70, color: AppTheme.primary.withValues(alpha: 0.3))),
                      ),
                      errorWidget: (context, url, error) => Center(
                          child: Icon(hall['icon'] as IconData? ?? Icons.account_balance_outlined,
                              size: 70, color: AppTheme.primary)),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.primaryLight, AppTheme.primaryLight.withBlue(220)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(hall['icon'] as IconData? ?? Icons.account_balance_outlined,
                            size: 70, color: AppTheme.primary),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                                3,
                                (i) => Container(
                                      width: i == 0 ? 20 : 6,
                                      height: 6,
                                      margin: const EdgeInsets.only(right: 4),
                                      decoration: BoxDecoration(
                                        color: i == 0 ? AppTheme.primary : AppTheme.cardBorder,
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ))),
                      ]),
                    ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(hall['name'] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text('${hall['location']} · ', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                      const Icon(Icons.star_outline, size: 14, color: AppTheme.textSecondary),
                      const SizedBox(width: 2),
                      Text('${hall['rating']} (${hall['reviewCount'] ?? hall['reviews'] ?? 0} reviews)',
                          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
                    ]),
                  ])),
                  Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(hall['price'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.primary)),
                    StatusBadge(label: hall['status'] ?? 'Available', type: StatusType.success),
                  ]),
                ]),
                const SizedBox(height: 20),
                const Text('Amenities', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Wrap(children: ((hall['amenities'] as List<dynamic>?) ?? []).map((a) => AmenityChip(label: a.toString())).toList()),
                const SizedBox(height: 20),
                const Text('About this venue', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(
                  (hall['description'] as String?)?.isNotEmpty == true
                      ? hall['description'] as String
                      : 'Spacious pillarless ballroom ideal for gala dinners, product launches, and large corporate events. Natural light from floor-to-ceiling windows. Fully air-conditioned with state-of-the-art AV equipment and dedicated event support staff.',
                  style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.6),
                ),
                const SizedBox(height: 20),
                const Text('Guest reviews', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                _buildReview('Farah A.', '"Excellent facilities and very responsive staff. Our conference went very smoothly."', '4.9'),
                _buildReview('David L.', '"Great ambience and good AV setup. Parking could be slightly improved."', '4.6'),
                _buildReview('Nora H.', '"Perfect for our annual gala dinner. Highly recommended!"', '5.0'),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: AppTheme.cardBorder)),
        ),
        child: ElevatedButton(
          onPressed: () => Navigator.pushNamed(context, '/user/date-time', arguments: hall),
          child: const Text('Check Availability & Book'),
        ),
      ),
    );
  }

  Widget _buildReview(String name, String text, String stars) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.cardBorder),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(radius: 14, backgroundColor: AppTheme.primaryLight,
                child: Text(name[0], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primaryDark))),
            const SizedBox(width: 8),
            Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const Spacer(),
            const Icon(Icons.star_outline, size: 12, color: AppTheme.textSecondary),
            const SizedBox(width: 2),
            Text(stars, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ]),
          const SizedBox(height: 8),
          Text(text, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.4)),
        ]),
      );
}
