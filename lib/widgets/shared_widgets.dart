import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

// ── Status Badge ────────────────────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String label;
  final StatusType type;
  const StatusBadge({super.key, required this.label, required this.type});

  @override
  Widget build(BuildContext context) {
    final colors = {
      StatusType.success: (AppTheme.successLight, AppTheme.success),
      StatusType.warning: (AppTheme.warningLight, AppTheme.warning),
      StatusType.danger: (AppTheme.dangerLight, AppTheme.danger),
      StatusType.info: (AppTheme.primaryLight, AppTheme.primaryDark),
      StatusType.neutral: (const Color(0xFFF1EFE8), const Color(0xFF444441)),
    };
    final (bg, fg) = colors[type]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.1), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg, letterSpacing: 0.3),
      ),
    );
  }
}

enum StatusType { success, warning, danger, info, neutral }

// ── Section Header ────────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const SectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title.toUpperCase(),
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: AppTheme.textSecondary)),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// ── Venue Card ────────────────────────────────────────────────────────────────
class VenueCard extends StatefulWidget {
  final String name, location, capacity, rating, price, type;
  final StatusType status;
  final String statusLabel;
  final String? imageUrl;
  final IconData icon;
  final Color emojiBg;
  final VoidCallback? onTap;
  final bool compact;
  final String? heroTag;

  const VenueCard({
    super.key,
    required this.name,
    required this.location,
    required this.capacity,
    required this.rating,
    required this.price,
    required this.type,
    this.status = StatusType.success,
    this.statusLabel = 'Available',
    this.imageUrl,
    this.icon = Icons.account_balance_outlined,
    this.emojiBg = AppTheme.primaryLight,
    this.onTap,
    this.compact = false,
    this.heroTag,
  });

  @override
  State<VenueCard> createState() => _VenueCardState();
}

class _VenueCardState extends State<VenueCard> with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) => _pressController.forward();
  void _onTapUp(TapUpDetails details) => _pressController.reverse();
  void _onTapCancel() => _pressController.reverse();

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap?.call();
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.cardBorder, width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 15,
                offset: const Offset(0, 8),
              )
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: widget.compact ? _compactBody() : _fullBody(),
        ),
      ),
    );
  }

  Widget _fullBody() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              Hero(
                tag: widget.heroTag ?? widget.name,
                child: Container(
                  height: 190,
                  width: double.infinity,
                  decoration: BoxDecoration(color: widget.emojiBg),
                  child: widget.imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: widget.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: AppTheme.surface,
                            child: const Center(
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: AppTheme.primary)),
                          ),
                          errorWidget: (context, url, error) => Center(
                              child: Icon(widget.icon, size: 48, color: AppTheme.textTertiary)),
                        )
                      : Center(child: Icon(widget.icon, size: 48, color: AppTheme.primary)),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: StatusBadge(label: widget.statusLabel, type: widget.status),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.3)],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Expanded(
                  child: Text(widget.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.2)),
                ),
                Text(widget.price,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.primary)),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textSecondary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text('${widget.location} · ${widget.capacity} pax',
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
                ),
                const Icon(Icons.star, size: 14, color: Color(0xFFF59E0B)),
                const SizedBox(width: 2),
                Text(widget.rating,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              ]),
            ]),
          ),
        ],
      );

  Widget _compactBody() => Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: widget.emojiBg,
              borderRadius: BorderRadius.circular(14),
            ),
            clipBehavior: Clip.antiAlias,
            child: widget.imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: widget.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary)),
                    errorWidget: (context, url, error) => Center(
                        child: Icon(widget.icon, size: 28, color: AppTheme.primary)),
                  )
                : Center(child: Icon(widget.icon, size: 32, color: AppTheme.primary)),
          ),
          const SizedBox(width: 14),
          Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(widget.name,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              Text(widget.price,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.primary)),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.location_on_outlined, size: 13, color: AppTheme.textSecondary),
              const SizedBox(width: 2),
              Text('${widget.location} · ${widget.capacity} pax',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              const Icon(Icons.star, size: 13, color: Color(0xFFF59E0B)),
              const SizedBox(width: 2),
              Text(widget.rating,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
              const Spacer(),
              StatusBadge(label: widget.statusLabel, type: widget.status),
            ]),
          ])),
        ]),
      );
}

// ── Amenity Chip ─────────────────────────────────────────────────────────────
class AmenityChip extends StatelessWidget {
  final String label;
  const AmenityChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(right: 8, bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          border: Border.all(color: AppTheme.cardBorder),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 12, color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
      );
}

// ── Filter Chip Row ───────────────────────────────────────────────────────────
class FilterChipRow extends StatelessWidget {
  final List<String> chips;
  final int selected;
  final ValueChanged<int> onSelected;
  const FilterChipRow({super.key, required this.chips, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: List.generate(chips.length, (i) {
            final isSelected = selected == i;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                onSelected(i);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primary : Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                      color: isSelected ? AppTheme.primary : AppTheme.cardBorder,
                      width: 1.2),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4))
                        ]
                      : null,
                ),
                child: Text(chips[i],
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? Colors.white : AppTheme.textSecondary)),
              ),
            );
          }),
        ),
      );
}

// ── Progress Steps ────────────────────────────────────────────────────────────
class BookingProgressBar extends StatelessWidget {
  final int currentStep, totalSteps;
  final List<String> labels;
  const BookingProgressBar({super.key, required this.currentStep, required this.totalSteps, required this.labels});

  @override
  Widget build(BuildContext context) => Column(children: [
        Row(children: List.generate(totalSteps, (i) {
          final done = i < currentStep;
          final active = i == currentStep;
          return Expanded(child: Row(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 28, height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done || active ? AppTheme.primary : Colors.white,
                border: Border.all(
                    color: done || active ? AppTheme.primary : AppTheme.cardBorder,
                    width: 2),
              ),
              child: Center(child: done
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : Text('${i + 1}', style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w800,
                      color: active ? Colors.white : AppTheme.textTertiary))),
            ),
            if (i < totalSteps - 1)
              Expanded(child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 3,
                color: done ? AppTheme.primary : AppTheme.cardBorder,
              )),
          ]));
        })),
        const SizedBox(height: 10),
        Row(children: List.generate(totalSteps, (i) => Expanded(
              child: Text(labels[i],
                  style: TextStyle(
                      fontSize: 10,
                      color: i <= currentStep ? AppTheme.primary : AppTheme.textTertiary,
                      fontWeight: i == currentStep ? FontWeight.w800 : FontWeight.w500),
                  textAlign: TextAlign.center),
            ))),
      ]);
}

// ── Search Bar ────────────────────────────────────────────────────────────────
class AppSearchBar extends StatelessWidget {
  final String hint;
  final VoidCallback? onFilter;
  final ValueChanged<String>? onChanged;
  const AppSearchBar({super.key, required this.hint, this.onFilter, this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.cardBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(children: [
          const Icon(Icons.search, color: AppTheme.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              onChanged: onChanged,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(fontSize: 14, color: AppTheme.textTertiary, fontWeight: FontWeight.w400),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                fillColor: Colors.transparent,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (onFilter != null) ...[
            Container(width: 1, height: 24, color: AppTheme.cardBorder, margin: const EdgeInsets.symmetric(horizontal: 8)),
            IconButton(
              onPressed: onFilter,
              icon: const Icon(Icons.tune, size: 20, color: AppTheme.primary),
              constraints: const BoxConstraints(),
              padding: EdgeInsets.zero,
            ),
          ],
        ]),
      );
}

// ── Bottom Navigation ────────────────────────────────────────────────────────
class UserBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const UserBottomNav({super.key, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 20, offset: const Offset(0, -5))
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (i) {
            HapticFeedback.mediumImpact();
            onTap(i);
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppTheme.primary,
          unselectedItemColor: AppTheme.textTertiary,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home_rounded), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), activeIcon: Icon(Icons.explore_rounded), label: 'Browse'),
            BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), activeIcon: Icon(Icons.calendar_month_rounded), label: 'Bookings'),
            BottomNavigationBarItem(icon: Icon(Icons.person_2_outlined), activeIcon: Icon(Icons.person_2_rounded), label: 'Profile'),
          ],
        ),
      );
}

// ── Info Banner ───────────────────────────────────────────────────────────────
class InfoBanner extends StatelessWidget {
  final String message;
  final Color bgColor, textColor;
  final IconData icon;
  const InfoBanner({super.key, required this.message, required this.bgColor,
      required this.textColor, this.icon = Icons.info_outline});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: textColor.withValues(alpha: 0.1)),
        ),
        child: Row(children: [
          Icon(icon, size: 18, color: textColor),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: TextStyle(fontSize: 13, color: textColor, fontWeight: FontWeight.w600))),
        ]),
      );
}

// ── Price Summary Row ─────────────────────────────────────────────────────────
class PriceRow extends StatelessWidget {
  final String label, value;
  final bool isTotal;
  const PriceRow({super.key, required this.label, required this.value, this.isTotal = false});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(
              fontSize: isTotal ? 15 : 14,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
              color: isTotal ? AppTheme.textPrimary : AppTheme.textSecondary)),
          Text(value, style: TextStyle(
              fontSize: isTotal ? 17 : 14,
              fontWeight: isTotal ? FontWeight.w900 : FontWeight.w700,
              color: isTotal ? AppTheme.primary : AppTheme.textPrimary)),
        ]),
      );
}

// ── Empty State ──────────────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: AppTheme.primary),
            ),
            const SizedBox(height: 24),
            Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
            const SizedBox(height: 10),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: AppTheme.textSecondary, height: 1.5)),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

