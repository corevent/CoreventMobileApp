import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

import '../../../core/design_system/app_surfaces.dart';
import '../../../core/design_system/app_tokens.dart';
import '../../../core/design_system/icon_label.dart';
import '../../../core/theme/app_colors.dart';
import '../../favorites/presentation/event_favorite_button.dart';
import '../../ratings/presentation/rating_summary.dart';
import '../data/event_dtos.dart';
import '../domain/event_catalog.dart';

String eventDate(BuildContext context, DateTime value) {
  final local = value.toLocal();
  final date = MaterialLocalizations.of(context).formatMediumDate(local);
  final time = MaterialLocalizations.of(
    context,
  ).formatTimeOfDay(TimeOfDay.fromDateTime(local), alwaysUse24HourFormat: true);
  return '$date · $time';
}

String eventLocation(String locationName, String? locationType) {
  if (locationType == 'online') return 'Evento online';
  if (locationName.trim().isEmpty) return 'Local a confirmar';
  return locationName;
}

String eventCardLocation(EventSummary event) {
  final location = eventLocation(event.locationName, event.locationType);
  if (event.locationType == 'online') return location;
  final city = event.cityName?.trim() ?? '';
  final state = event.stateAcronym?.trim() ?? '';
  if (city.isEmpty || location.toLowerCase().contains(city.toLowerCase())) {
    return location;
  }
  return '$location · $city${state.isEmpty ? '' : ' — $state'}';
}

class EventArtwork extends StatelessWidget {
  const EventArtwork({super.key, required this.url, this.radius = 0});

  final String? url;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final resolved = url?.trim();
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: resolved == null || resolved.isEmpty
          ? const _ArtworkFallback()
          : Image.network(
              resolved,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : const _ArtworkFallback(),
              errorBuilder: (_, _, _) => const _ArtworkFallback(),
            ),
    );
  }
}

class _ArtworkFallback extends StatelessWidget {
  const _ArtworkFallback();

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: AppColors.orangeSoft,
    child: const Center(
      child: Icon(RemixIcons.ticket_line, size: 36, color: AppColors.primary),
    ),
  );
}

class EventSummaryCard extends StatefulWidget {
  const EventSummaryCard({
    super.key,
    required this.event,
    required this.onTap,
    this.featured = false,
    this.action,
  });

  final EventSummary event;
  final VoidCallback onTap;
  final bool featured;
  final Widget? action;

  @override
  State<EventSummaryCard> createState() => _EventSummaryCardState();
}

class _EventSummaryCardState extends State<EventSummaryCard> {
  bool pressed = false;

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    return Semantics(
      button: true,
      explicitChildNodes: true,
      label: 'Abrir prévia de ${event.title}',
      child: Listener(
        onPointerDown: (_) => setState(() => pressed = true),
        onPointerUp: (_) => setState(() => pressed = false),
        onPointerCancel: (_) => setState(() => pressed = false),
        child: AnimatedScale(
          scale: pressed ? .985 : 1,
          duration: AppMotion.duration(context, AppMotion.quick),
          curve: AppMotion.curve,
          child: Material(
            color: AppColors.surface,
            shape: AppSurfaces.cardShape,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: widget.onTap,
              splashColor: Colors.transparent,
              highlightColor: AppColors.orangeSoft,
              child: _EventCardContent(
                event: event,
                featured: widget.featured,
                action: widget.action ?? EventFavoriteButton(eventId: event.id),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EventCardContent extends StatelessWidget {
  const _EventCardContent({
    required this.event,
    required this.action,
    required this.featured,
  });

  final EventSummary event;
  final Widget action;
  final bool featured;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final enlarged = MediaQuery.textScalerOf(context).scale(16) >= 24;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: constraints.maxWidth * (featured ? 9 / 16 : .5),
            child: Stack(
              fit: StackFit.expand,
              children: [
                EventArtwork(url: event.bannerUrl),
                Positioned(
                  top: 8,
                  left: 12,
                  right: 12,
                  child: _PosterHeader(event: event, action: action),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  maxLines: enlarged ? null : 3,
                  overflow: enlarged ? null : TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: featured ? 20 : 16,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                _DetailLine(
                  RemixIcons.calendar_event_line,
                  eventDate(context, event.startDate),
                  wrap: true,
                ),
                const SizedBox(height: 6),
                _DetailLine(
                  RemixIcons.map_pin_line,
                  eventCardLocation(event),
                  wrap: true,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    EventAverageRating(
                      value: event.averageRating,
                      count: event.ratingCount,
                    ),
                    if (event.isAdultOnly)
                      const _Tag('+18', AppColors.pinkSoft, AppColors.pink),
                  ],
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
}

class _PosterHeader extends StatelessWidget {
  const _PosterHeader({required this.event, required this.action});

  final EventSummary event;
  final Widget action;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Expanded(
        child: Align(
          alignment: Alignment.centerLeft,
          child: _Tag(
            EventCatalog.categoryLabel(event.category),
            AppColors.surface,
            AppColors.primaryDark,
          ),
        ),
      ),
      const SizedBox(width: 8),
      Material(
        color: AppColors.surface,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: SizedBox(width: 48, height: 48, child: Center(child: action)),
      ),
    ],
  );
}

class _Tag extends StatelessWidget {
  const _Tag(this.label, this.background, this.foreground);

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    ),
  );
}

class _DetailLine extends StatelessWidget {
  const _DetailLine(this.icon, this.text, {this.wrap = false});

  final IconData icon;
  final String text;
  final bool wrap;

  @override
  Widget build(BuildContext context) => CoreventIconLabel(
    icon: icon,
    label: text,
    iconSize: 17,
    iconColor: AppColors.textSecondary,
    maxLines: wrap ? null : 1,
    style: const TextStyle(
      color: AppColors.textSecondary,
      fontSize: 12,
      height: 1.4,
    ),
  );
}

class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _block(22, 180),
      const SizedBox(height: 14),
      _block(230, double.infinity),
      const SizedBox(height: 25),
      _block(22, 160),
      const SizedBox(height: 12),
      _block(280, double.infinity),
      const SizedBox(height: 12),
      _block(280, double.infinity),
    ],
  );

  Widget _block(double height, double width) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(14),
      ),
    ),
  );
}
