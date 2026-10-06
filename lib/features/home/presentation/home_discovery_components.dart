import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

import '../../../core/design_system/app_surfaces.dart';
import '../../../core/theme/app_colors.dart';
import '../../events/data/event_dtos.dart';
import '../../events/domain/event_catalog.dart';
import '../../events/presentation/event_widgets.dart';
import '../domain/home_feed.dart';
import 'feed_components.dart';

class HomeInterestGrid extends StatelessWidget {
  const HomeInterestGrid({super.key, required this.onSelected});
  final ValueChanged<String> onSelected;
  static const interests = homeInterests;
  static const icons = [
    RemixIcons.music_2_line,
    RemixIcons.palette_line,
    RemixIcons.restaurant_line,
    RemixIcons.run_line,
    RemixIcons.code_s_slash_line,
    RemixIcons.book_open_line,
  ];

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final enlarged = MediaQuery.textScalerOf(context).scale(16) >= 24;
      final columns = enlarged && constraints.maxWidth < 600
          ? 1
          : constraints.maxWidth >= 700
          ? 3
          : 2;
      final width = (constraints.maxWidth - 10 * (columns - 1)) / columns;
      return Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          for (var i = 0; i < interests.length; i++)
            SizedBox(
              width: width,
              child: Material(
                color: AppColors.surface,
                shape: AppSurfaces.cardShape,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => onSelected(interests[i]),
                  splashColor: Colors.transparent,
                  highlightColor: AppColors.orangeSoft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 64),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            icons[i],
                            size: 22,
                            color: AppColors.primaryDark,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              EventCatalog.categoryLabel(interests[i]),
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      );
    },
  );
}

class HomeEventCollection extends StatelessWidget {
  const HomeEventCollection({
    super.key,
    required this.events,
    required this.onOpen,
  });
  final List<EventSummary> events;
  final ValueChanged<EventSummary> onOpen;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final enlarged = MediaQuery.textScalerOf(context).scale(16) >= 24;
      final columns = !enlarged && constraints.maxWidth >= 700 ? 2 : 1;
      final width = (constraints.maxWidth - 16 * (columns - 1)) / columns;
      return Wrap(
        spacing: 16,
        runSpacing: 14,
        children: [
          for (final event in events)
            SizedBox(
              width: width,
              child: FeedReveal(
                key: ValueKey('home-event-${event.id}'),
                child: EventSummaryCard(
                  event: event,
                  onTap: () => onOpen(event),
                ),
              ),
            ),
        ],
      );
    },
  );
}
